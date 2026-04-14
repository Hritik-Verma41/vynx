import { Request, Response, Router } from "express";
import jwt from "jsonwebtoken";

import { protect } from "../middlewares/authMiddleware";
import { Contact } from "../models/Contact";
import { User } from "../models/User";

const contactsRouter: Router = Router();

const QR_SECRET = process.env.CONTACT_QR_SECRET || process.env.JWT_ACCESS_SECRET || "vynx-contact-secret";

async function ensureMutualContact(
    ownerId: string,
    contactUserId: string,
    source: "phone" | "qr"
) {
    const exists = await Contact.findOne({ owner: ownerId, contactUser: contactUserId });
    if (!exists) {
        await Contact.create({
            owner: ownerId,
            contactUser: contactUserId,
            source,
        });
    }
}

const digitsOnly = (raw: string): string =>
    String(raw || "").replace(/[^\d]/g, "");

const normalizeE164 = (raw: string): string => {
    let value = String(raw || "").trim();
    if (!value) return "";

    if (value.startsWith("00")) value = `+${value.slice(2)}`;
    const hasPlus = value.startsWith("+");
    const digits = digitsOnly(value);
    if (digits.length < 8) return "";

    return hasPlus ? `+${digits}` : "";
};

const phoneVariants = (normalizedE164: string): string[] => {
    if (!normalizedE164) return [];
    const withoutPlus = normalizedE164.startsWith("+")
        ? normalizedE164.slice(1)
        : normalizedE164;
    return Array.from(new Set([normalizedE164, withoutPlus]));
};

const buildPhonebookCandidates = (
    raw: string,
    defaultCountryCode?: string
): string[] => {
    const candidates = new Set<string>();
    const value = String(raw || "").trim();
    if (!value) return [];

    const hasExplicitCountry = value.startsWith("+") || value.startsWith("00");
    const digits = digitsOnly(value);
    if (digits.length < 8) return [];

    if (hasExplicitCountry) {
        candidates.add(`+${digits}`);
        candidates.add(digits);
    } else {
        if (digits.length > 10) {
            candidates.add(`+${digits}`);
            candidates.add(digits);
        } else {
            candidates.add(digits);
        }

        const cc = digitsOnly(defaultCountryCode || "");
        if (cc.length > 0) {
            candidates.add(`+${cc}${digits}`);
            candidates.add(`${cc}${digits}`);
        } else if (digits.length === 10) {
            // Safe fallback for common local format without country code.
            candidates.add(`+91${digits}`);
            candidates.add(`91${digits}`);
        }
    }

    return Array.from(candidates);
};

const getUserId = (req: Request): string => (req as any).user._id.toString();

contactsRouter.get("/", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);

        const contacts = await Contact.find({ owner: userId })
            .populate("contactUser", "firstName lastName phoneNumber profileImage status")
            .sort({ updatedAt: -1 });

        return res.status(200).json({ success: true, contacts });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/add-by-phone", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const rawPhone = req.body?.phoneNumber;

        if (typeof rawPhone !== "string" || rawPhone.trim().length === 0) {
            return res.status(400).json({ success: false, message: "phoneNumber is required." });
        }

        const normalized = normalizeE164(rawPhone);
        if (!normalized) {
            return res.status(400).json({ success: false, message: "Invalid phone number." });
        }

        const variants = phoneVariants(normalized);
        const contactUser = await User.findOne({ phoneNumber: { $in: variants } });

        if (!contactUser) {
            return res.status(404).json({ success: false, message: "No Vynx user found with this phone number." });
        }

        if (contactUser._id.toString() === ownerId) {
            return res.status(400).json({ success: false, message: "You cannot add yourself." });
        }

        const existing = await Contact.findOne({ owner: ownerId, contactUser: contactUser._id });
        if (existing) {
            return res.status(200).json({ success: true, message: "Already in contacts.", contact: existing, alreadyExists: true });
        }

        await ensureMutualContact(ownerId, contactUser._id.toString(), "phone");
        await ensureMutualContact(contactUser._id.toString(), ownerId, "phone");

        const populated = await Contact.findOne({
            owner: ownerId,
            contactUser: contactUser._id,
        }).populate("contactUser", "firstName lastName phoneNumber profileImage status");

        return res.status(201).json({ success: true, message: "Contact added.", contact: populated });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/match-phonebook", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const phoneNumbers = req.body?.phoneNumbers;
        const defaultCountryCodeRaw = req.body?.defaultCountryCode;
        const defaultCountryCode =
            typeof defaultCountryCodeRaw === "string" ? defaultCountryCodeRaw : "";

        if (!Array.isArray(phoneNumbers)) {
            return res.status(400).json({ success: false, message: "phoneNumbers array is required." });
        }

        const normalizedSet = new Set<string>();
        for (const number of phoneNumbers) {
            if (typeof number !== "string") continue;
            for (const candidate of buildPhonebookCandidates(number, defaultCountryCode)) {
                normalizedSet.add(candidate);
            }
        }

        const normalizedList = Array.from(normalizedSet);
        if (normalizedList.length === 0) {
            return res.status(200).json({ success: true, matches: [] });
        }

        const users = await User.find(
            { phoneNumber: { $in: normalizedList }, _id: { $ne: ownerId } },
            "firstName lastName phoneNumber profileImage status"
        );

        const existingContacts = await Contact.find({ owner: ownerId }).select("contactUser");
        const existingSet = new Set(existingContacts.map((c) => c.contactUser.toString()));

        const matches = users.map((u) => ({
            user: u,
            isAlreadyContact: existingSet.has(u._id.toString()),
        }));

        return res.status(200).json({ success: true, matches });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.delete("/:contactId", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;

        const existing = await Contact.findOne({ _id: contactId, owner: ownerId });
        if (!existing) {
            return res.status(404).json({ success: false, message: "Contact not found." });
        }

        await Contact.deleteOne({ _id: existing._id, owner: ownerId });

        // Keep reciprocal relation in sync because add flow creates both sides.
        await Contact.deleteMany({
            owner: existing.contactUser,
            contactUser: ownerId,
        });

        return res.status(200).json({ success: true, message: "Contact removed." });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.get("/me/qr", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);

        const token = jwt.sign(
            { t: "contact_add", uid: userId },
            QR_SECRET,
            { expiresIn: "10m" }
        );

        return res.status(200).json({
            success: true,
            token,
            qrPayload: token,
        });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/add-by-qr", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const tokenRaw = req.body?.token;

        if (typeof tokenRaw !== "string" || tokenRaw.trim().length === 0) {
            return res.status(400).json({ success: false, message: "token is required." });
        }

        const decoded = jwt.verify(tokenRaw.trim(), QR_SECRET) as { t: string; uid: string };
        if (decoded.t !== "contact_add" || !decoded.uid) {
            return res.status(400).json({ success: false, message: "Invalid QR payload." });
        }

        if (decoded.uid === ownerId) {
            return res.status(400).json({ success: false, message: "You cannot add yourself." });
        }

        const targetUser = await User.findById(decoded.uid);
        if (!targetUser) {
            return res.status(404).json({ success: false, message: "User not found." });
        }

        const existing = await Contact.findOne({ owner: ownerId, contactUser: targetUser._id });
        if (existing) {
            return res.status(200).json({ success: true, message: "Already in contacts.", contact: existing, alreadyExists: true });
        }

        await ensureMutualContact(ownerId, targetUser._id.toString(), "qr");
        await ensureMutualContact(targetUser._id.toString(), ownerId, "qr");

        const populated = await Contact.findOne({
            owner: ownerId,
            contactUser: targetUser._id,
        }).populate("contactUser", "firstName lastName phoneNumber profileImage status");

        return res.status(201).json({ success: true, message: "Contact added.", contact: populated });
    } catch (error: any) {
        if (error?.name === "TokenExpiredError") {
            return res.status(400).json({ success: false, message: "QR expired. Please try again." });
        }
        if (error?.name === "JsonWebTokenError") {
            return res.status(400).json({ success: false, message: "Invalid QR token." });
        }
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.patch("/:contactId/block", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;

        const contact = await Contact.findOneAndUpdate(
            { _id: contactId, owner: ownerId },
            { $set: { isBlocked: true } },
            { new: true }
        );

        if (!contact) {
            return res.status(404).json({ success: false, message: "Contact not found." });
        }

        return res.status(200).json({ success: true, contact });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.patch("/:contactId/unblock", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;

        const contact = await Contact.findOneAndUpdate(
            { _id: contactId, owner: ownerId },
            { $set: { isBlocked: false } },
            { new: true }
        );

        if (!contact) {
            return res.status(404).json({ success: false, message: "Contact not found." });
        }

        return res.status(200).json({ success: true, contact });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

export default contactsRouter;
