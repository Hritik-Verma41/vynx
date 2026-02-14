import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { User } from "../models/User";

const userRouter: Router = Router();

userRouter.post('/link-provider', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const { provider, uid } = req.body;

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ success: false, message: "User not found" });

        if (user.providers.includes(provider)) {
            return res.status(400).json({ success: false, message: `${provider} is already linked.` });
        }

        const updateField = provider === 'google' ? { googleUid: uid } : { facebookUid: uid };

        user.set(updateField);
        user.providers.push(provider);
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
