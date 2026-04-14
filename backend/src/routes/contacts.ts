import { Request, Response, Router } from "express";
import jwt from "jsonwebtoken";

import { protect } from "../middlewares/authMiddleware";
import { Contact } from "../models/Contact";
import { User } from "../models/User";
import {
    sendContactAcceptedPush,
    sendContactRejectedPush,
    sendContactRequestPush,
} from "../services/pushNotificationService";

const contactsRouter: Router = Router();
const QR_SECRET = process.env.CONTACT_QR_SECRET || process.env.JWT_ACCESS_SECRET || "vynx-contact-secret";

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
            candidates.add(`+91${digits}`);
            candidates.add(`91${digits}`);
        }
    }

    return Array.from(candidates);
};

const getUserId = (req: Request): string => (req as any).user._id.toString();

async function setPendingPair(
    requesterId: string,
    targetId: string,
    source: "phone" | "qr"
) {
    await Contact.findOneAndUpdate(
        { owner: requesterId, contactUser: targetId },
        {
            $set: {
                source,
                relationStatus: "pending_outgoing",
                requestedBy: requesterId
            }
        },
        { upsert: true, new: true, runValidators: true }
    );

    await Contact.findOneAndUpdate(
        { owner: targetId, contactUser: requesterId },
        {
            $set: {
                source,
                relationStatus: "pending_incoming",
                requestedBy: requesterId
            }
        },
        { upsert: true, new: true, runValidators: true }
    );
}

async function setAcceptedPair(userA: string, userB: string) {
    await Contact.findOneAndUpdate(
        { owner: userA, contactUser: userB },
        {
            $set: {
                relationStatus: "accepted",
                requestedBy: null
            }
        },
        { upsert: true, new: true, runValidators: true }
    );

    await Contact.findOneAndUpdate(
        { owner: userB, contactUser: userA },
        {
            $set: {
                relationStatus: "accepted",
                requestedBy: null
            }
        },
        { upsert: true, new: true, runValidators: true }
    );
}

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

async function createOrTransitionRequest(
    ownerId: string,
    targetId: string,
    source: "phone" | "qr",
    ownerName: string
) {
    const existing = await Contact.findOne({ owner: ownerId, contactUser: targetId });

    if (!existing) {
        await setPendingPair(ownerId, targetId, source);
        await sendContactRequestPush(targetId, ownerName);
        return { code: "REQUEST_SENT", message: "Contact request sent." };
    }

    if (existing.relationStatus === "accepted") {
        return { code: "ALREADY_ADDED", message: "Already in contacts." };
    }

    if (existing.relationStatus === "pending_outgoing") {
        return { code: "REQUEST_PENDING", message: "Contact request already pending." };
    }

    if (existing.relationStatus === "pending_incoming") {
        await setAcceptedPair(ownerId, targetId);
        await sendContactAcceptedPush(targetId, ownerName);
        return { code: "REQUEST_ACCEPTED", message: "Request accepted. Contact added." };
    }

    await setPendingPair(ownerId, targetId, source);
    await sendContactRequestPush(targetId, ownerName);
    return { code: "REQUEST_SENT", message: "Contact request sent." };
}

contactsRouter.post("/add-by-phone", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const rawPhone = req.body?.phoneNumber;
        const owner = await User.findById(ownerId).select("firstName lastName");
        const ownerName = owner
            ? `${owner.firstName} ${owner.lastName || ""}`.trim()
            : "Someone";

        if (typeof rawPhone !== "string" || rawPhone.trim().length === 0) {
            return res.status(400).json({ success: false, message: "phoneNumber is required." });
        }

        const normalized = normalizeE164(rawPhone);
        if (!normalized) {
            return res.status(400).json({ success: false, message: "Invalid phone number." });
        }

        const contactUser = await User.findOne({
            phoneNumber: { $in: phoneVariants(normalized) }
        });

        if (!contactUser) {
            return res.status(404).json({ success: false, message: "No Vynx user found with this phone number." });
        }

        if (contactUser._id.toString() === ownerId) {
            return res.status(400).json({ success: false, message: "You cannot add yourself." });
        }

        const result = await createOrTransitionRequest(
            ownerId,
            contactUser._id.toString(),
            "phone",
            ownerName
        );

        const ownerContact = await Contact.findOne({
            owner: ownerId,
            contactUser: contactUser._id
        }).populate("contactUser", "firstName lastName phoneNumber profileImage status");

        return res.status(200).json({
            success: true,
            code: result.code,
            message: result.message,
            contact: ownerContact
        });
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

        const existingRelations = await Contact.find({
            owner: ownerId,
            contactUser: { $in: users.map((u) => u._id) }
        }).select("_id contactUser relationStatus");

        const relationMap = new Map(
            existingRelations.map((r) => [
                r.contactUser.toString(),
                {
                    contactId: r._id.toString(),
                    relationStatus: r.relationStatus
                }
            ])
        );

        const matches = users.map((u) => {
            const relation = relationMap.get(u._id.toString());
            return {
                user: u,
                relationStatus: relation?.relationStatus ?? "none",
                contactId: relation?.contactId ?? null
            };
        });

        return res.status(200).json({ success: true, matches });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/:contactId/accept", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;
        const owner = await User.findById(ownerId).select("firstName lastName");
        const ownerName = owner
            ? `${owner.firstName} ${owner.lastName || ""}`.trim()
            : "Someone";

        const incoming = await Contact.findOne({
            _id: contactId,
            owner: ownerId,
            relationStatus: "pending_incoming"
        });

        if (!incoming) {
            return res.status(404).json({ success: false, message: "Pending request not found." });
        }

        await setAcceptedPair(ownerId, incoming.contactUser.toString());
        await sendContactAcceptedPush(incoming.contactUser.toString(), ownerName);

        return res.status(200).json({
            success: true,
            code: "REQUEST_ACCEPTED",
            message: "Contact request accepted."
        });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/:contactId/reject", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;
        const owner = await User.findById(ownerId).select("firstName lastName");
        const ownerName = owner
            ? `${owner.firstName} ${owner.lastName || ""}`.trim()
            : "Someone";

        const incoming = await Contact.findOne({
            _id: contactId,
            owner: ownerId,
            relationStatus: "pending_incoming"
        });

        if (!incoming) {
            return res.status(404).json({ success: false, message: "Pending request not found." });
        }

        await Contact.findOneAndUpdate(
            { owner: ownerId, contactUser: incoming.contactUser },
            { $set: { relationStatus: "rejected", requestedBy: null } },
            { new: true }
        );

        await Contact.findOneAndUpdate(
            { owner: incoming.contactUser, contactUser: ownerId },
            { $set: { relationStatus: "rejected", requestedBy: null } },
            { new: true }
        );
        await sendContactRejectedPush(incoming.contactUser.toString(), ownerName);

        return res.status(200).json({
            success: true,
            code: "REQUEST_REJECTED",
            message: "Contact request rejected."
        });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

contactsRouter.post("/:contactId/cancel", protect, async (req: Request, res: Response) => {
    try {
        const ownerId = getUserId(req);
        const { contactId } = req.params;

        const outgoing = await Contact.findOne({
            _id: contactId,
            owner: ownerId,
            relationStatus: "pending_outgoing"
        });

        if (!outgoing) {
            return res.status(404).json({ success: false, message: "Pending request not found." });
        }

        await Contact.deleteOne({ _id: outgoing._id, owner: ownerId });
        await Contact.deleteMany({
            owner: outgoing.contactUser,
            contactUser: ownerId,
            relationStatus: "pending_incoming"
        });

        return res.status(200).json({
            success: true,
            code: "REQUEST_CANCELED",
            message: "Contact request canceled."
        });
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
        const owner = await User.findById(ownerId).select("firstName lastName");
        const ownerName = owner
            ? `${owner.firstName} ${owner.lastName || ""}`.trim()
            : "Someone";

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

        const result = await createOrTransitionRequest(
            ownerId,
            targetUser._id.toString(),
            "qr",
            ownerName
        );

        const ownerContact = await Contact.findOne({
            owner: ownerId,
            contactUser: targetUser._id,
        }).populate("contactUser", "firstName lastName phoneNumber profileImage status");

        return res.status(200).json({
            success: true,
            code: result.code,
            message: result.message,
            contact: ownerContact
        });
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
