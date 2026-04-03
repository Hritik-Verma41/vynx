import { Request, Response, Router } from "express";
import { protect } from "../middlewares/authMiddleware";
import { DataUsageSettings } from "../models/DataUsageSettings";

const dataUsageSettingsRouter: Router = Router();

dataUsageSettingsRouter.get("/", protect, async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user._id;
        let settings = await DataUsageSettings.findOne({ user: userId });

        if (!settings) {
            settings = await DataUsageSettings.create({ user: userId });
        }

        return res.status(200).json({ success: true, settings });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

dataUsageSettingsRouter.patch("/update", protect, async (req: Request, res: Response) => {
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
                message: "updatedAt is invalid."
            });
        }

        let settings = await DataUsageSettings.findOne({ user: userId });

        if (settings) {
            const existingDate = new Date(settings.updatedAt);
            if (incomingDate <= existingDate) {
                return res.status(200).json({
                    success: true,
                    message: "Server has newer or equal date. Sync ignored.",
                    settings
                });
            }
        }

        settings = await DataUsageSettings.findOneAndUpdate(
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

export default dataUsageSettingsRouter;