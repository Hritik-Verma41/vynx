import { Request, Response, Router } from "express";
import mongoose from "mongoose";

import { protect } from "../middlewares/authMiddleware";
import { Conversation } from "../models/Conversation";
import { Message } from "../models/Message";

const conversationsRouter: Router = Router();

function getUserId(req: Request): string {
    return (req as any).user._id.toString();
}

async function getOrCreateDirectConversation(userA: string, userB: string) {
    const sorted = [userA, userB].sort();
    const membersKey = sorted.join(":");

    let conversation = await Conversation.findOne({ type: "direct", membersKey });
    if (!conversation) {
        conversation = await Conversation.create({
            type: "direct",
            members: sorted.map((id) => new mongoose.Types.ObjectId(id)),
            admins: [new mongoose.Types.ObjectId(userA)],
            membersKey,
        });
    }
    return conversation;
}

function isConversationMember(conversation: any, userId: string) {
    return (conversation.members ?? []).some((m: any) => m.toString() === userId);
}

function isConversationAdmin(conversation: any, userId: string) {
    return (conversation.admins ?? []).some((a: any) => a.toString() === userId);
}

conversationsRouter.get("/", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);

        const conversations = await Conversation.find({ members: userId })
            .sort({ updatedAt: -1 })
            .populate("members", "firstName lastName profileImage status")
            .populate("admins", "firstName lastName profileImage");
        const conversationIds = conversations.map((c) => c._id);
        const unreadRows = await Message.aggregate([
            {
                $match: {
                    conversation: { $in: conversationIds },
                    recipients: new mongoose.Types.ObjectId(userId),
                    readBy: { $ne: new mongoose.Types.ObjectId(userId) },
                }
            },
            { $group: { _id: "$conversation", count: { $sum: 1 } } }
        ]);
        const unreadMap = new Map(
            unreadRows.map((row) => [String(row._id), Number(row.count ?? 0)])
        );
        const withUnread = conversations.map((c: any) => ({
            ...c.toObject(),
            unreadCount: unreadMap.get(c._id.toString()) ?? 0,
        }));

        return res.status(200).json({ success: true, conversations: withUnread });
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

        const conversation = await getOrCreateDirectConversation(userId, otherUserId);
        return res.status(200).json({ success: true, conversation });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.post("/groups", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const nameRaw = req.body?.name;
        const memberIdsRaw = req.body?.memberIds;
        const description = req.body?.description ? String(req.body.description) : null;
        const avatar = req.body?.avatar ? String(req.body.avatar) : null;

        const name = String(nameRaw ?? "").trim();
        if (name.length < 2) {
            return res.status(400).json({ success: false, message: "Group name is required." });
        }

        if (!Array.isArray(memberIdsRaw)) {
            return res.status(400).json({ success: false, message: "memberIds must be an array." });
        }

        const uniqueMembers = new Set<string>([
            userId,
            ...memberIdsRaw.map((id: unknown) => String(id)).filter((id) => id.length > 0),
        ]);

        if (uniqueMembers.size < 3) {
            return res.status(400).json({
                success: false,
                message: "At least 3 members (including you) are required for a group."
            });
        }

        const members = Array.from(uniqueMembers).map((id) => new mongoose.Types.ObjectId(id));

        const conversation = await Conversation.create({
            type: "group",
            name,
            description,
            avatar,
            members,
            createdBy: new mongoose.Types.ObjectId(userId),
            admins: [new mongoose.Types.ObjectId(userId)],
        });

        const populated = await Conversation.findById(conversation._id)
            .populate("members", "firstName lastName profileImage status")
            .populate("admins", "firstName lastName profileImage");

        return res.status(201).json({ success: true, conversation: populated });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.get("/:conversationId", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const conversation = await Conversation.findById(conversationId)
            .populate("members", "firstName lastName profileImage status phoneNumber")
            .populate("admins", "firstName lastName profileImage");
        if (!conversation) {
            return res.status(404).json({ success: false, message: "Conversation not found" });
        }
        if (!isConversationMember(conversation, userId)) {
            return res.status(403).json({ success: false, message: "Not allowed" });
        }
        return res.status(200).json({ success: true, conversation });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.patch("/:conversationId/group", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const conversation = await Conversation.findById(conversationId);
        if (!conversation || conversation.type !== "group") {
            return res.status(404).json({ success: false, message: "Group not found" });
        }
        if (!isConversationAdmin(conversation, userId)) {
            return res.status(403).json({ success: false, message: "Only admins can edit group." });
        }

        const updates: Record<string, unknown> = {};
        if (typeof req.body?.name === "string" && req.body.name.trim().length >= 2) {
            updates.name = req.body.name.trim();
        }
        if (typeof req.body?.description === "string") {
            updates.description = req.body.description.trim();
        }
        if (typeof req.body?.avatar === "string") {
            updates.avatar = req.body.avatar.trim();
        }

        const updated = await Conversation.findByIdAndUpdate(
            conversationId,
            { $set: updates },
            { new: true, runValidators: true }
        )
            .populate("members", "firstName lastName profileImage status phoneNumber")
            .populate("admins", "firstName lastName profileImage");

        return res.status(200).json({ success: true, conversation: updated });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.post("/:conversationId/group/members", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const memberIdsRaw = req.body?.memberIds;
        if (!Array.isArray(memberIdsRaw) || memberIdsRaw.length === 0) {
            return res.status(400).json({ success: false, message: "memberIds is required." });
        }

        const conversation = await Conversation.findById(conversationId);
        if (!conversation || conversation.type !== "group") {
            return res.status(404).json({ success: false, message: "Group not found" });
        }
        if (!isConversationAdmin(conversation, userId)) {
            return res.status(403).json({ success: false, message: "Only admins can add members." });
        }

        const existing = new Set(conversation.members.map((m) => m.toString()));
        const toAdd = memberIdsRaw
            .map((id: unknown) => String(id))
            .filter((id: string) => id.length > 0 && !existing.has(id))
            .map((id: string) => new mongoose.Types.ObjectId(id));

        if (toAdd.length > 0) {
            conversation.members.push(...toAdd);
            await conversation.save();
        }

        const updated = await Conversation.findById(conversationId)
            .populate("members", "firstName lastName profileImage status phoneNumber")
            .populate("admins", "firstName lastName profileImage");

        return res.status(200).json({ success: true, conversation: updated });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.delete("/:conversationId/group/members/:memberId", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const memberId = String(req.params.memberId);

        const conversation = await Conversation.findById(conversationId);
        if (!conversation || conversation.type !== "group") {
            return res.status(404).json({ success: false, message: "Group not found" });
        }
        const requesterIsAdmin = isConversationAdmin(conversation, userId);
        const isSelf = memberId === userId;
        if (!requesterIsAdmin && !isSelf) {
            return res.status(403).json({ success: false, message: "Not allowed" });
        }

        conversation.members = conversation.members.filter((m) => m.toString() !== memberId);
        conversation.admins = conversation.admins.filter((a) => a.toString() !== memberId);

        if (conversation.members.length === 0) {
            await Conversation.findByIdAndDelete(conversationId);
            return res.status(200).json({ success: true, deleted: true });
        }
        if (conversation.admins.length === 0) {
            conversation.admins = [conversation.members[0]];
        }
        await conversation.save();

        const updated = await Conversation.findById(conversationId)
            .populate("members", "firstName lastName profileImage status phoneNumber")
            .populate("admins", "firstName lastName profileImage");

        return res.status(200).json({ success: true, conversation: updated });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.get("/:conversationId/messages", protect, async (req: Request, res: Response) => {
    try {
        const userId = getUserId(req);
        const conversationId = String(req.params.conversationId);
        const limit = Math.min(Number(req.query.limit ?? 40), 150);
        const before = req.query.before ? new Date(String(req.query.before)) : null;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ success: false, message: "Conversation not found" });
        }

        const isMember = conversation.members.some((m) => m.toString() === userId);
        if (!isMember) {
            return res.status(403).json({ success: false, message: "Not allowed" });
        }

        const query: Record<string, unknown> = { conversation: conversationId };
        if (before && !Number.isNaN(before.getTime())) {
            query.createdAt = { $lt: before };
        }

        const messages = await Message.find(query)
            .sort({ createdAt: -1 })
            .limit(limit)
            .populate("sender", "firstName lastName profileImage")
            .populate("readBy", "firstName lastName profileImage");

        return res.status(200).json({
            success: true,
            messages: messages.reverse(),
        });
    } catch {
        return res.status(500).json({ success: false, message: "Internal Server Error" });
    }
});

conversationsRouter.patch(
    "/messages/:messageId/read",
    protect,
    async (req: Request, res: Response) => {
        try {
            const userId = getUserId(req);
            const messageId = String(req.params.messageId);

            const message = await Message.findById(messageId);
            if (!message) {
                return res.status(404).json({ success: false, message: "Message not found" });
            }

            if (!message.recipients.some((id) => id.toString() === userId)) {
                return res.status(403).json({ success: false, message: "Not allowed" });
            }

            const alreadyRead = message.readBy.some((id) => id.toString() === userId);
            if (!alreadyRead) {
                message.readBy.push(new mongoose.Types.ObjectId(userId));
                if (!message.readAt) {
                    message.readAt = new Date();
                }
                await message.save();
            }

            return res.status(200).json({ success: true, message });
        } catch {
            return res.status(500).json({ success: false, message: "Internal Server Error" });
        }
    }
);

conversationsRouter.patch(
    "/messages/:messageId/poll-vote",
    protect,
    async (req: Request, res: Response) => {
        try {
            const userId = getUserId(req);
            const messageId = String(req.params.messageId);
            const optionIdsRaw = req.body?.optionIds;

            const optionIds = Array.isArray(optionIdsRaw)
                ? optionIdsRaw.map((id: unknown) => String(id))
                : [];

            if (optionIds.length === 0) {
                return res.status(400).json({ success: false, message: "optionIds is required." });
            }

            const message = await Message.findById(messageId);
            if (!message || message.kind !== "poll" || !message.poll) {
                return res.status(404).json({ success: false, message: "Poll message not found." });
            }

            if (!message.recipients.some((id) => id.toString() === userId) &&
                message.sender.toString() !== userId) {
                return res.status(403).json({ success: false, message: "Not allowed" });
            }

            if (!message.poll.multipleChoice && optionIds.length > 1) {
                return res.status(400).json({ success: false, message: "Multiple votes not allowed." });
            }

            const validOptionIds = new Set((message.poll.options ?? []).map((o) => o.id));
            if (!optionIds.every((id) => validOptionIds.has(id))) {
                return res.status(400).json({ success: false, message: "Invalid poll option." });
            }

            message.poll.votes = (message.poll.votes ?? []).filter(
                (vote) => vote.userId.toString() !== userId
            );
            const now = new Date();
            for (const optionId of optionIds) {
                message.poll.votes.push({
                    userId: new mongoose.Types.ObjectId(userId),
                    optionId,
                    votedAt: now,
                });
            }
            await message.save();

            return res.status(200).json({ success: true, message });
        } catch {
            return res.status(500).json({ success: false, message: "Internal Server Error" });
        }
    }
);

export default conversationsRouter;
