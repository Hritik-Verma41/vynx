import { Server as HttpServer } from "http";
import jwt from "jsonwebtoken";
import mongoose from "mongoose";
import { Server, Socket } from "socket.io";

import { Conversation } from "../models/Conversation";
import { Message } from "../models/Message";

const onlineUsers = new Map<string, Set<string>>();

const userRoom = (userId: string) => `user:${userId}`;
const conversationRoom = (conversationId: string) => `conversation:${conversationId}`;

function addOnlineUser(userId: string, socketId: string) {
    const existing = onlineUsers.get(userId) ?? new Set<string>();
    existing.add(socketId);
    onlineUsers.set(userId, existing);
}

function removeOnlineUser(userId: string, socketId: string) {
    const existing = onlineUsers.get(userId);
    if (!existing) return;
    existing.delete(socketId);
    if (existing.size === 0) {
        onlineUsers.delete(userId);
    }
}

function isUserOnline(userId: string): boolean {
    return (onlineUsers.get(userId)?.size ?? 0) > 0;
}

function parseSocketToken(socket: Socket): string | null {
    const authToken = socket.handshake.auth?.token;
    const headerAuth = socket.handshake.headers.authorization;

    const raw =
        typeof authToken === "string"
            ? authToken
            : typeof headerAuth === "string"
                ? headerAuth
                : null;

    if (!raw) return null;
    return raw.startsWith("Bearer ") ? raw.slice(7) : raw;
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

function buildMessagePreview(
    kind: string,
    payload: Record<string, unknown>
): string {
    if (kind === "text") return String(payload.text ?? "");
    if (kind === "image") return "📷 Photo";
    if (kind === "video") return "🎬 Video";
    if (kind === "audio") return "🎵 Audio";
    if (kind === "location") return "📍 Location";
    if (kind === "contact") return "👤 Contact";
    if (kind === "document") return "📄 Document";
    if (kind === "poll") return "📊 Poll";
    if (kind === "event") return "📅 Event";
    return "📎 File";
}

async function joinUserToAllConversationRooms(userId: string, socket: Socket) {
    const conversations = await Conversation.find({ members: userId }).select("_id");
    for (const conversation of conversations) {
        socket.join(conversationRoom(conversation._id.toString()));
    }
}

async function processPendingDeliveryForOnlineUser(userId: string, io: Server) {
    const pending = await Message.find({
        recipients: userId,
        deliveredTo: { $ne: new mongoose.Types.ObjectId(userId) },
    });
    if (pending.length === 0) return;

    const now = new Date();
    for (const msg of pending) {
        const alreadyDelivered = msg.deliveredTo.some((id) => id.toString() === userId);
        if (alreadyDelivered) continue;
        msg.deliveredTo.push(new mongoose.Types.ObjectId(userId));
        if (!msg.deliveredAt) msg.deliveredAt = now;
        await msg.save();

        io.to(userRoom(msg.sender.toString())).emit("message:delivered", {
            messageId: msg._id.toString(),
            conversationId: msg.conversation.toString(),
            userId,
            deliveredAt: now.toISOString(),
        });

        const recipientIds = msg.recipients.map((id) => id.toString());
        const deliveredIds = msg.deliveredTo.map((id) => id.toString());
        const allDelivered = recipientIds.every((id) => deliveredIds.includes(id));
        if (allDelivered && msg.kind === "text" && msg.deleteWhenDelivered) {
            const deletedPayload = {
                messageId: msg._id.toString(),
                conversationId: msg.conversation.toString(),
                reason: "delivered",
            };
            await Message.findByIdAndDelete(msg._id);
            io.to(conversationRoom(msg.conversation.toString())).emit("message:deleted", deletedPayload);
        }
    }
}

export function initSocketServer(httpServer: HttpServer) {
    const io = new Server(httpServer, {
        cors: { origin: "*" },
    });

    io.use((socket, next) => {
        try {
            const token = parseSocketToken(socket);
            if (!token) return next(new Error("Missing token"));
            const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET!) as { id: string };
            socket.data.userId = decoded.id;
            next();
        } catch {
            next(new Error("Invalid token"));
        }
    });

    io.on("connection", async (socket) => {
        const userId = socket.data.userId as string;
        addOnlineUser(userId, socket.id);
        socket.join(userRoom(userId));
        await joinUserToAllConversationRooms(userId, socket);
        await processPendingDeliveryForOnlineUser(userId, io);

        socket.on("conversation:get_or_create", async (payload, ack) => {
            try {
                const otherUserId = String(payload?.otherUserId ?? "");
                if (!otherUserId) {
                    return ack?.({ success: false, message: "otherUserId is required" });
                }
                const conversation = await getOrCreateDirectConversation(userId, otherUserId);
                socket.join(conversationRoom(conversation._id.toString()));
                return ack?.({ success: true, conversation });
            } catch {
                return ack?.({ success: false, message: "Failed to create conversation" });
            }
        });

        socket.on("conversation:create_group", async (payload, ack) => {
            try {
                const name = String(payload?.name ?? "").trim();
                const memberIdsRaw: unknown[] = Array.isArray(payload?.memberIds)
                    ? payload.memberIds
                    : [];
                if (name.length < 2) {
                    return ack?.({ success: false, message: "Group name is required." });
                }
                const allMemberIds = new Set<string>([
                    userId,
                    ...memberIdsRaw
                        .map((id: unknown) => String(id))
                        .filter((id: string) => id.length > 0),
                ]);
                if (allMemberIds.size < 3) {
                    return ack?.({ success: false, message: "Need at least 3 members including you." });
                }

                const conversation = await Conversation.create({
                    type: "group",
                    name,
                    description: payload?.description ? String(payload.description) : null,
                    avatar: payload?.avatar ? String(payload.avatar) : null,
                    members: Array.from(allMemberIds).map((id) => new mongoose.Types.ObjectId(id)),
                    createdBy: new mongoose.Types.ObjectId(userId),
                    admins: [new mongoose.Types.ObjectId(userId)],
                });

                io.to(Array.from(allMemberIds).map((id) => userRoom(id))).emit(
                    "conversation:created",
                    { conversation }
                );
                return ack?.({ success: true, conversation });
            } catch {
                return ack?.({ success: false, message: "Failed to create group" });
            }
        });

        socket.on("message:send", async (payload, ack) => {
            try {
                const kind = String(payload?.kind ?? "");
                const allowedKinds = new Set([
                    "text",
                    "file",
                    "image",
                    "video",
                    "audio",
                    "location",
                    "contact",
                    "document",
                    "poll",
                    "event",
                ]);
                if (!allowedKinds.has(kind)) {
                    return ack?.({ success: false, message: "Invalid message kind" });
                }

                let conversationId = String(payload?.conversationId ?? "");
                const recipientId = String(payload?.recipientId ?? "");
                if (!conversationId) {
                    if (!recipientId) {
                        return ack?.({
                            success: false,
                            message: "conversationId or recipientId is required",
                        });
                    }
                    const conversation = await getOrCreateDirectConversation(userId, recipientId);
                    conversationId = conversation._id.toString();
                }

                const conversation = await Conversation.findById(conversationId);
                if (!conversation) {
                    return ack?.({ success: false, message: "Conversation not found" });
                }
                const isMember = conversation.members.some((m) => m.toString() === userId);
                if (!isMember) {
                    return ack?.({ success: false, message: "Not allowed" });
                }

                socket.join(conversationRoom(conversationId));

                const memberIds = conversation.members.map((m) => m.toString());
                const recipients = memberIds.filter((id) => id !== userId);
                const deliveredTo = recipients
                    .filter((id) => isUserOnline(id))
                    .map((id) => new mongoose.Types.ObjectId(id));

                const now = new Date();
                const isDirect = conversation.type === "direct";

                const message = await Message.create({
                    conversation: conversation._id,
                    sender: new mongoose.Types.ObjectId(userId),
                    recipient: isDirect && recipients.length > 0
                        ? new mongoose.Types.ObjectId(recipients[0])
                        : null,
                    recipients: recipients.map((id) => new mongoose.Types.ObjectId(id)),
                    kind,
                    text: payload?.text ? String(payload.text) : null,
                    file: payload?.file ?? null,
                    location: payload?.location ?? null,
                    sharedContact: payload?.sharedContact ?? null,
                    poll: payload?.poll
                        ? {
                            ...payload.poll,
                            votes: [],
                        }
                        : null,
                    event: payload?.event ?? null,
                    deliveredAt: deliveredTo.length > 0 ? now : null,
                    deliveredTo,
                    readBy: [new mongoose.Types.ObjectId(userId)],
                    downloadedBy: [],
                    deleteWhenDelivered: Boolean(payload?.deleteWhenDelivered ?? false),
                });

                const preview = buildMessagePreview(kind, payload ?? {});
                await Conversation.findByIdAndUpdate(conversation._id, {
                    $set: {
                        lastMessage: preview,
                        lastMessageType: kind,
                        lastMessageAt: now,
                    },
                });

                const messagePayload = {
                    _id: message._id.toString(),
                    conversation: message.conversation.toString(),
                    sender: message.sender.toString(),
                    recipient: message.recipient?.toString() ?? null,
                    recipients: message.recipients.map((id) => id.toString()),
                    kind: message.kind,
                    text: message.text,
                    file: message.file,
                    location: message.location,
                    sharedContact: message.sharedContact,
                    poll: message.poll,
                    event: message.event,
                    deliveredAt: message.deliveredAt,
                    readAt: message.readAt,
                    downloadedAt: message.downloadedAt,
                    deliveredTo: message.deliveredTo.map((id) => id.toString()),
                    readBy: message.readBy.map((id) => id.toString()),
                    downloadedBy: message.downloadedBy.map((id) => id.toString()),
                    createdAt: message.createdAt,
                };

                io.to(conversationRoom(conversationId)).emit("message:new", messagePayload);
                io.to(userRoom(userId)).emit("conversation:updated", {
                    conversationId,
                    lastMessage: preview,
                    lastMessageType: kind,
                    lastMessageAt: now.toISOString(),
                });

                for (const id of recipients) {
                    io.to(userRoom(id)).emit("conversation:updated", {
                        conversationId,
                        lastMessage: preview,
                        lastMessageType: kind,
                        lastMessageAt: now.toISOString(),
                    });
                }

                if (deliveredTo.length > 0) {
                    io.to(userRoom(userId)).emit("message:delivered", {
                        messageId: message._id.toString(),
                        conversationId,
                        deliveredTo: deliveredTo.map((id) => id.toString()),
                        deliveredAt: now.toISOString(),
                    });
                }

                return ack?.({ success: true, message: messagePayload });
            } catch {
                return ack?.({ success: false, message: "Failed to send message" });
            }
        });

        socket.on("typing:start", async (payload) => {
            try {
                const conversationId = String(payload?.conversationId ?? "");
                if (!conversationId) return;
                const conversation = await Conversation.findById(conversationId).select("members");
                if (!conversation) return;
                const isMember = conversation.members.some((m) => m.toString() === userId);
                if (!isMember) return;
                socket.join(conversationRoom(conversationId));
                socket.to(conversationRoom(conversationId)).emit("typing:start", {
                    conversationId,
                    userId,
                });
            } catch {
                return;
            }
        });

        socket.on("typing:stop", async (payload) => {
            try {
                const conversationId = String(payload?.conversationId ?? "");
                if (!conversationId) return;
                const conversation = await Conversation.findById(conversationId).select("members");
                if (!conversation) return;
                const isMember = conversation.members.some((m) => m.toString() === userId);
                if (!isMember) return;
                socket.join(conversationRoom(conversationId));
                socket.to(conversationRoom(conversationId)).emit("typing:stop", {
                    conversationId,
                    userId,
                });
            } catch {
                return;
            }
        });

        socket.on("message:read", async (payload, ack) => {
            try {
                const messageId = String(payload?.messageId ?? "");
                if (!messageId) return ack?.({ success: false, message: "messageId is required" });

                const message = await Message.findById(messageId);
                if (!message) return ack?.({ success: false, message: "Message not found" });

                const isRecipient = message.recipients.some((id) => id.toString() === userId);
                if (!isRecipient) {
                    return ack?.({ success: false, message: "Not allowed" });
                }

                const hasRead = message.readBy.some((id) => id.toString() === userId);
                if (!hasRead) {
                    message.readBy.push(new mongoose.Types.ObjectId(userId));
                    if (!message.readAt) message.readAt = new Date();
                    await message.save();
                }

                io.to(conversationRoom(message.conversation.toString())).emit("message:read", {
                    messageId: message._id.toString(),
                    conversationId: message.conversation.toString(),
                    userId,
                    readAt: new Date().toISOString(),
                });

                return ack?.({ success: true });
            } catch {
                return ack?.({ success: false, message: "Failed to mark as read" });
            }
        });

        socket.on("message:file_download", async (payload, ack) => {
            try {
                const messageId = String(payload?.messageId ?? "");
                if (!messageId) return ack?.({ success: false, message: "messageId is required" });

                const message = await Message.findById(messageId);
                if (!message) return ack?.({ success: false, message: "Message not found" });
                if (!["file", "image", "video", "audio", "document"].includes(message.kind)) {
                    return ack?.({ success: false, message: "Message is not file/media type" });
                }
                const isRecipient = message.recipients.some((id) => id.toString() === userId);
                if (!isRecipient) {
                    return ack?.({ success: false, message: "Not allowed" });
                }

                const hasDownloaded = message.downloadedBy.some((id) => id.toString() === userId);
                if (!hasDownloaded) {
                    message.downloadedBy.push(new mongoose.Types.ObjectId(userId));
                    if (!message.downloadedAt) message.downloadedAt = new Date();
                    await message.save();
                }

                io.to(conversationRoom(message.conversation.toString())).emit("message:file_downloaded", {
                    messageId: message._id.toString(),
                    conversationId: message.conversation.toString(),
                    userId,
                    downloadedAt: new Date().toISOString(),
                });

                return ack?.({ success: true });
            } catch {
                return ack?.({ success: false, message: "Failed to mark file downloaded" });
            }
        });

        socket.on("poll:vote", async (payload, ack) => {
            try {
                const messageId = String(payload?.messageId ?? "");
                const optionIds: string[] = Array.isArray(payload?.optionIds)
                    ? payload.optionIds.map((id: unknown) => String(id))
                    : [];
                if (!messageId || optionIds.length === 0) {
                    return ack?.({ success: false, message: "messageId and optionIds are required" });
                }

                const message = await Message.findById(messageId);
                if (!message || message.kind !== "poll" || !message.poll) {
                    return ack?.({ success: false, message: "Poll not found" });
                }

                const isMember =
                    message.sender.toString() === userId ||
                    message.recipients.some((id) => id.toString() === userId);
                if (!isMember) {
                    return ack?.({ success: false, message: "Not allowed" });
                }

                const validOptions = new Set((message.poll.options ?? []).map((o) => o.id));
                if (!optionIds.every((id: string) => validOptions.has(id))) {
                    return ack?.({ success: false, message: "Invalid option" });
                }

                if (!message.poll.multipleChoice && optionIds.length > 1) {
                    return ack?.({ success: false, message: "Multiple choice not allowed" });
                }

                message.poll.votes = (message.poll.votes ?? []).filter(
                    (vote) => vote.userId.toString() !== userId
                );
                const now = new Date();
                optionIds.forEach((optionId: string) => {
                    message.poll!.votes.push({
                        userId: new mongoose.Types.ObjectId(userId),
                        optionId,
                        votedAt: now,
                    });
                });
                await message.save();

                io.to(conversationRoom(message.conversation.toString())).emit("poll:updated", {
                    messageId: message._id.toString(),
                    conversationId: message.conversation.toString(),
                    poll: message.poll,
                });

                return ack?.({ success: true, poll: message.poll });
            } catch {
                return ack?.({ success: false, message: "Failed to vote on poll" });
            }
        });

        socket.on("disconnect", () => {
            removeOnlineUser(userId, socket.id);
        });
    });

    return io;
}
