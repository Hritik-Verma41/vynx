import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { NotificationSettings } from "../models/NotificationSettings";

const notificationSettingsRouter: Router = Router();

notificationSettingsRouter.get("/" , protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        let settings = await NotificationSettings.findOne({ user: userId });

        if(!settings) {
            settings = await NotificationSettings.create({ user: userId });
        }

        return res.status(200).json({ success: true, settings });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

notificationSettingsRouter.patch("/update", protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        const { updatedAt, ...otherUpdates } = req.body;

        if(!updatedAt) {
            return res.status(400).json({
                success: false,
                message: "updatedAt is required."
            });
        }

        const incomingDate = new Date(updatedAt);
        if(Number.isNaN(incomingDate.getTime())) {
            return res.status(400).json({
                success: false,
                message: "updatedAt is invalid."
            });
        }

        let settings = await NotificationSettings.findOne({ user: userId });

        if(settings) { 
            const existingDate = new Date(settings.updatedAt);
            if(incomingDate <= existingDate) {
                return res.status(200).json({
                    success: true,
                    message: "Server has newer or equal date. Sync ignored.",
                    settings
                });
            }
        }

        settings = await NotificationSettings.findOneAndUpdate(
            { user: userId },
            { $set: { ...otherUpdates, updatedAt: incomingDate } },
            { new: true, upsert: true, runValidators: true }
        );

        return res.status(200).json({ success: true, settings });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

export default notificationSettingsRouter;
