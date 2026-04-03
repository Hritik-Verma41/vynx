import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { User } from "../models/User";

const userRouter: Router = Router();

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

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            {
                $set: {
                    firstName,
                    lastName,
                    phoneNumber,
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

export default userRouter;
