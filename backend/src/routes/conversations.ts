import { Request, Response, Router } from "express";
import cloudinary from "../config/cloudinary";
import { Conversation } from "../models/Conversation";
import mongoose from "mongoose";
import { protect } from "../middlewares/authMiddleware";
import { Message } from "../models/Message";

const conversationsRouter: Router = Router();

function getUserId(req: Request): string {
    return (req as any).user._id.toString();
}

async function destroyCloudinaryFile(publicId?: string | null) {
    if (!publicId) return;
    try {
        await cloudinary.uploader.destroy(publicId, { resource_type: "auto" });
    } catch {
        // non-blocking cleanup
    }
}

async function getOrCreateConversation(userA: string, userB: string) {
    const sorted = [userA, userB].sort();
    const membersKey = sorted.join(":");

    let conversation = await Conversation.findOne({ membersKey });
    if (!conversation) {
        conversation = await Conversation.create({
            members: sorted.map((id) => new mongoose.Types.ObjectId(id)),
            membersKey,
        });
    }
    return conversation;
}

conversationsRouter.get("/", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);

        const conversations = await Conversation.find({ members: userId })
            .sort({ updatedAt: -1 })
            .populate("members", "firstName lastName profileImage status");

        return res.status(200).json({ success: true, conversations });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.post("/with/:otherUserId", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const otherUserId = String(req.params.otherUserId);

        if (!otherUserId) {
            return res.status(400).json({ success: false, message: "otherUserId is required" });
        }

        const conversation = await getOrCreateConversation(userId, otherUserId);
        return res.status(200).json({ success: true, conversation });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.get("/:conversationId/messages", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const limit = Math.min(Number(req.query.limit ?? 30), 100);
        const before = req.query.before ? new Date(String(req.query.before)) : null;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ success: false, message: "Converstation not found" });
        }

        const isMember = conversation.members.some((m) => m.toString() === userId);
        if (!isMember) {
            return res.status(403).json({ success: false, message: "Not allowed" });
        }

        const query: any = { conversation: conversationId };
        if (before) query.createdAt = { $lt: before };

        const messages = await Message.find(query).sort({ createdAt: -1 }).limit(limit);

        return res.status(200).json({
            success: true,
            messages: messages.reverse()
        });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.patch("/messages/:messsageId/read", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const messageId = String(req.params.messageId);
        
        const message = await Message.findById(messageId);
        if (!message) {
            return res.status(404).json({ success: false, message: "Message not found" });
        }

        if (message.recipient.toString() !== userId) {
            return res.status(403).json({ success: false, message: "Not allowed" });
        }

        if (!message.readAt) {
            message.readAt = new Date();
            await message.save();
        }

        return res.status(200).json({ success: true, message });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});


conversationsRouter.patch(
    "/messsages/:messageId/file-downloaded",
    protect,
    async (req: Request, res: Response) => {
        try {
            const userId = getUserId(req);
            const messageId = String(req.params.messageId);

            const message = await Message.findById(messageId);
            if (!message) {
                return res.status(404).json({ success: false, message: "Message not found" });
            }

            if (message.recipient.toString() !== userId) {
                return res.status(403).json({ success: false, message: "Not allowed" });
            }

            if (message.kind !== "file") {
                return res.status(400).json({ success: false, message: "Message is not file type" });
            }

            message.downloadedAt = new Date();
            await message.save();

            await destroyCloudinaryFile(message.file?.publicId);
            await Message.findByIdAndDelete(message._id);

            return res.status(200).json({ success: true, deletedMessageId: message._id });
        } catch {
            return res.status(500).json({ success: false, message: "Internal Server Error" });
        }
    }
);

export default conversationsRouter;
