import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import mongoose from "mongoose";
import cloudinary from "../config/cloudinary";
import { Conversation } from "../models/Conversation";
import { Server, Socket } from "socket.io";
import { Message } from "../models/Message";

const onlineUsers = new Map<string, Set<string>>();

const userRoom = (userId: string) => `user:${userId}`;

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

async function destroyCloudinaryFile(publicId?: string | null) {
    if (!publicId) return;
    try {
        await cloudinary.uploader.destroy(publicId, { resource_type: "auto" });
    } catch {
        // Ignore cloudinary cleanup errors to avoid blocking message cleanup
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

async function processPendingDeliveryForOnlineUser(userId: string, io: Server) {
    const pending = await Message.find({
        recipient: userId,
        deliveredAt: null,
    });

    if (pending.length === 0) return;

    const now = new Date();
    const ids = pending.map((m) => m._id);

    await Message.updateMany(
        { _id: { $in: ids } },
        { $set: { deliveredAt: now } }
    );

    for (const m of pending) {
        io.to(userRoom(m.sender.toString())).emit("message:delivered", {
            messageId: m._id.toString(),
            conversationId: m.conversation.toString(),
            deliveredAt: now.toString(),
        });
    }

    const toDelete = pending.filter((m) => m.kind === "text" && m.deleteWhenDelivered);
    if (toDelete.length === 0) return;

    const deleteIds = toDelete.map((m) => m._id);
    await Message.deleteMany({ _id: { $in: deleteIds } });

    for (const m of toDelete) {
        const payload = {
            messageId: m._id.toString(),
            conversationId: m.conversation.toString(),
            reason: "delivered",
        };
        io.to(userRoom(m.sender.toString())).emit("message:deleted", payload);
        io.to(userRoom(m.recipient.toString())).emit("message:deleted", payload);
    }
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

export function initSocketServer(httpServer: HttpServer) {
    const io = new Server(httpServer, {
        cors: { origin: "*" }
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

        await processPendingDeliveryForOnlineUser(userId, io);

        socket.on("conversation:get_or_create", async (payload, ack) => {
            try {
                const otherUserId = String(payload?.otherUserId ?? "");
                if (!otherUserId) {
                    return ack?.({ success: false, message: "otherUserId is required" });
                }

                const conversation = await getOrCreateConversation(userId, otherUserId);
                return ack?.({ success: true, conversation });
            } catch (error) {
                return ack?.({ success: false, message: "Failed to create covnersation" });
            }
        });

        socket.on("message:send", async (payload, ack) => {
            try {
                const kind = String(payload?.kind ?? "") as "text" | "file";
                const text = payload?.text ? String(payload.text) : null;
                const recipientId = String(payload?.recipientId ?? "");
                let conversationId = payload?.conversationId ? String(payload.conversationId) : "";

                if (!recipientId) {
                    return ack?.({ success: false, message: "recipientId is requried" });
                }

                if (kind !== "text" && kind !== "file") {
                    return ack?.({ success: false, message: "Invalid message kind" });
                }

                if (kind === 'text' && (!text || text.trim().length === 0)) {
                    return ack?.({ success: false, message: "Text message cannot be empty" });
                }

                if (kind === "file" && !payload?.file?.url) {
                    return ack?.({ success: false, message: "file.url is required for file messages" });
                }

                let conversation;
                if (conversationId) {
                    conversation = await Conversation.findById(conversationId);
                    if (!conversation) {
                        return ack?.({ success: false, message: "Conversation not found" });
                    }
                } else {
                    conversation = await getOrCreateConversation(userId, recipientId);
                    conversationId = conversation._id.toString();
                }

                const recipientOnline = isUserOnline(recipientId);
                const now = new Date();

                const message = await Message.create({
                    conversation: conversation._id,
                    sender: userId,
                    recipient: recipientId,
                    kind,
                    text: kind === "text" ? text : null,
                    file:
                        kind === "file"
                            ? {
                                url: String(payload.file.url),
                                publicId: payload.file.publicId ? String(payload.file.publicId) : null,
                                fileName: String(payload.file.fileName ?? "file"),
                                mimeType: String(payload.file.mimeType ?? "application/octet-stream"),
                                sizeBytes: Number(payload.file.sizeBytes ?? 0),
                            }
                            : null,
                    deliveredAt: recipientOnline ? now : null,
                    deleteWhenDelivered:
                        kind === "text" ? Boolean(payload?.deleteWhenDelivered ?? true) : false,
                });

                await Conversation.findByIdAndUpdate(conversation._id, {
                    $set: {
                        lastMessage: kind === "text" ? text : "File",
                        lastMessageType: kind,
                        lastMessageAt: now,
                    },
                });

                const messagePayload = {
                    _id: message._id.toString(),
                    conversation: message.conversation.toString(),
                    sender: message.sender.toString(),
                    recipient: message.recipient.toString(),
                    kind: message.kind,
                    text: message.text,
                    file: message.file,
                    deliveredAt: message.deliveredAt,
                    readAt: message.readAt,
                    downloadedAt: message.downloadedAt,
                    createdAt: message.createdAt,
                };

                io.to(userRoom(userId)).emit("message:new", messagePayload);
                io.to(userRoom(recipientId)).emit("message:new", messagePayload);

                if (recipientOnline) {
                    io.to(userRoom(userId)).emit("message:delivered", {
                        messageId: message._id.toString(),
                        conversationId: message.conversation.toString(),
                        deliveredAt: now.toISOString(),
                    });
                }

                if (recipientOnline && message.kind === "text" && message.deleteWhenDelivered) {
                    await Message.findByIdAndDelete(message._id);

                    const deletedPayload = {
                        messageId: message._id.toString(),
                        conversationId: message.conversation.toString(),
                        reason: "delivered",
                    };

                    io.to(userRoom(userId)).emit("message:deleted", deletedPayload);
                    io.to(userRoom(recipientId)).emit("message:deleted", deletedPayload);
                }

                return ack?.({ success: true, message: messagePayload });
            } catch {
                return ack?.({ success: false, message: "Failed to send message" });
            }
        });

        socket.on("message:read", async (payload, ack) => {
            try {
                const messageId = String(payload?.messageId ?? "");
                if (!messageId) return ack?.({ success: false, message: "messageId is required" });

                const message = await Message.findById(messageId);
                if (!message) return ack?.({ success: false, message: "Message not found" });

                if (message.recipient.toString() !== userId) {
                    return ack?.({ success: false, message: "Now allowed" });
                }

                if (!message.readAt) {
                    message.readAt = new Date();
                    await message.save();
                }

                io.to(userRoom(message.sender.toString())).emit("message:read", {
                    messageId: message._id.toString(),
                    conversationId: message.conversation.toString(),
                    readAt: message.readAt?.toISOString(),
                });

                return ack?.({ success: true });
            } catch {
                return ack?.({ success: false, message: "Failed to mark as read" });
            }
        });

        socket.on("message:file_download", async (payload, ack) => {
            try {
                const messageId = String(payload?.messageId ?? "");
                if(!messageId) return ack?.({ success: false, message: "messageId is required" });

                const message = await Message.findById(messageId);
                if (!message) return ack?.({ success: false, message: "Message not found" });

                if (message.recipient.toString() !== userId) {
                    return ack?.({ success: false, message: "Not allowed" });
                }

                if(message.kind !== "file") {
                    return ack?.({ success: false, message: "Message is not a file type" });
                }

                message.downloadedAt = new Date();
                await message.save();
                
                await destroyCloudinaryFile(message.file?.publicId);
                await Message.findByIdAndDelete(message._id);

                const deletedPayload = {
                    messageId: message._id.toString(),
                    conversationId: message.conversation.toString(),
                    reason: "downloaded",
                };

                io.to(userRoom(message.sender.toString())).emit("message:deleted", deletedPayload);
                io.to(userRoom(message.recipient.toString())).emit("message:deleted", deletedPayload);

                return ack?.({ success: true });
            } catch {
                return ack?.({ success: false, message: "Failed to mark the file downloaded" });
            }
        });

        socket.on("disconnect", () => {
            removeOnlineUser(userId, socket.id);
        });
    });

    return io;
}
