import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { User } from "../models/User";

const userRouter: Router = Router();

const normalizePhone = (raw: string): string => {
    let value = String(raw || "").trim();
    if (!value) return "";

    value = value.replace(/[^\d+]/g, "");
    if (value.startsWith("00")) value = `+${value.slice(2)}`;
    if (!value.startsWith("+")) value = `+${value}`;
    value = `+${value.replace(/[^\d]/g, "")}`;

    return value.length >= 8 ? value : "";
};

const phoneVariants = (normalized: string): string[] => {
    if (!normalized) return [];
    const withoutPlus = normalized.startsWith("+") ? normalized.slice(1) : normalized;
    return Array.from(new Set([normalized, withoutPlus]));
};

userRouter.post('/link-provider', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const providerRaw = req.body?.provider;
        const uidRaw = req.body?.uid;

        if (typeof providerRaw !== 'string') {
            return res.status(400).json({ success: false, message: "provider is required." });
        }
        const provider = providerRaw.trim().toLowerCase();
        if (provider !== 'google' && provider !== 'facebook') {
            return res.status(400).json({ success: false, message: "Invalid provider. Allowed: google, facebook." });
        }

        if (typeof uidRaw !== 'string' || uidRaw.trim().length === 0) {
            return res.status(400).json({ success: false, message: "uid is required." });
        }
        const uid = uidRaw.trim();

        const user = await User.findById(userId).select('-password -refreshToken');
        if (!user) return res.status(404).json({ success: false, message: "User not found" });

        if (user.providers.includes(provider)) {
            return res.status(400).json({ success: false, message: `${provider} is already linked.` });
        }

        const existing = provider === 'google'
            ? await User.findOne({ googleUid: uid })
            : await User.findOne({ facebookUid: uid });

        if (existing && existing._id.toString() !== userId.toString()) {
            return res.status(409).json({
                success: false,
                message: `This ${provider} account is already linked to another user.`
            });
        }

        const updateField = provider === 'google' ? { googleUid: uid } : { facebookUid: uid };

        user.set(updateField);
        user.providers.push(provider as any);
        await user.save();

        return res.status(200).json({
            success: true,
            message: `${provider} linked successfully`,
            user
        });
    } catch (error) {
        res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

userRouter.patch('/update-profile', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;

        const {
            firstName,
            lastName,
            phoneNumber,
            gender,
            status,
            profileImage
        } = req.body;

        const normalizedPhone = normalizePhone(phoneNumber || "");
        if (!normalizedPhone) {
            return res.status(400).json({
                success: false,
                message: "Invalid phone number."
            });
        }

        const clash = await User.findOne({
            _id: { $ne: userId },
            phoneNumber: { $in: phoneVariants(normalizedPhone) }
        });

        if (clash) {
            return res.status(409).json({
                success: false,
                message: "Phone number already in use."
            });
        }

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            {
                $set: {
                    firstName,
                    lastName,
                    phoneNumber: normalizedPhone,
                    gender,
                    status,
                    profileImage
                }
            },
            { new: true, runValidators: true }
        ).select('-password');

        if (!updatedUser) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        return res.status(200).json({
            success: true,
            message: "Profile updated successfully",
            user: updatedUser
        });
    } catch (error: any) {
        console.log("Update Profile Error: ", error);
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
})

userRouter.post('/device-token', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const tokenRaw = req.body?.token;
        if (typeof tokenRaw !== 'string' || tokenRaw.trim().length === 0) {
            return res.status(400).json({ success: false, message: "token is required." });
        }

        const token = tokenRaw.trim();
        await User.findByIdAndUpdate(
            userId,
            { $addToSet: { fcmTokens: token } },
            { new: true, runValidators: false }
        );

        return res.status(200).json({ success: true, message: "Device token saved." });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

userRouter.delete('/device-token', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const tokenRaw = req.body?.token;
        if (typeof tokenRaw !== 'string' || tokenRaw.trim().length === 0) {
            return res.status(400).json({ success: false, message: "token is required." });
        }

        const token = tokenRaw.trim();
        await User.findByIdAndUpdate(
            userId,
            { $pull: { fcmTokens: token } },
            { new: true }
        );

        return res.status(200).json({ success: true, message: "Device token removed." });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

export default userRouter;
