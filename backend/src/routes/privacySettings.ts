import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { PrivacySettings } from "../models/PrivacySettings";

const privacySettingsRouter: Router = Router();

privacySettingsRouter.get('/', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        let settings = await PrivacySettings.findOne({ user: userId });

        if (!settings) {
            settings = await PrivacySettings.create({ user: userId });
        }

        res.status(200).json({
            success: true,
            settings
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

privacySettingsRouter.patch('/update', protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const { updatedAt, ...otherUpdates } = req.body;

        if (!updatedAt) {
            return res.status(400).json({
                success: false,
                message: "updatedAt is required."
            });
        }

        const incomingDate = new Date(updatedAt);
        if (Number.isNaN(incomingDate.getTime())) {
            return res.status(400).json({
                success: false,
                message: "Invalid updatedAt value."
            });
        }

        let settings = await PrivacySettings.findOne({ user: userId });

        if (settings) {
            const existingDate = new Date(settings.updatedAt);

            if (incomingDate <= existingDate) {
                return res.status(200).json({
                    success: true,
                    message: "Server has newer or equal data. Sync ignored.",
                    settings
                });
            }
        }

        settings = await PrivacySettings.findOneAndUpdate(
            { user: userId },
            { $set: { ...otherUpdates, updatedAt: incomingDate } },
            { new: true, upsert: true, runValidators: true }
        );

        res.status(200).json({
            success: true,
            settings
        });
    } catch (error) {
        console.error("Privacy Update Error:", error);
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

export default privacySettingsRouter;
