import { model, Schema, Types } from "mongoose";

export interface IMessageFile {
    url: string,
    publicId?: string | null;
    fileName: string,
    mimeType: string,
    sizeBytes: number;
}

export interface IMessage {
    conversation: Types.ObjectId;
    sender: Types.ObjectId;
    recipient: Types.ObjectId;
    kind: "text" | "file";
    text?: string | null;
    file?: IMessageFile | null;

    deliveredAt?: Date | null;
    readAt?: Date | null;
    downloadedAt?: Date | null;

    // For text messages: clear from backend once delivered.
    deleteWhenDelivered: boolean;

    createdAt: Date;
    updatedAt: Date;
}

const messageFileSchema = new Schema<IMessageFile>(
    {
        url: { type: String, required: true },
        publicId: { type: String, default: null },
        fileName: { type: String, required: true },
        mimeType: { type: String, required: true },
        sizeBytes: { type: Number, required: true, min: 0 },
    },
    { _id: false }
);

const messageSchema = new Schema<IMessage>(
    {
        conversation: {
            type: Schema.Types.ObjectId,
            ref: "Conversation",
            required: true,
            index: true,
        },
        sender: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        recipient: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        kind: { type: String, enum: ["text", "file"], required: true, index: true },

        text: { type: String, default: null },
        file: { type: messageFileSchema, default: null },

        deliveredAt: { type: Date, default: null, index: true },
        readAt: { type: Date, default: null },
        downloadedAt: { type: Boolean, default: null, index: true },

        deleteWhenDelivered: { type: Boolean, default: true, index: true },
    },
    { timestamps: true }
);

messageSchema.index({ conversation: 1, createdAt: -1 });
messageSchema.index({ recipient: 1, deliveredAt: 1 });

export const Message = model<IMessage>("Message", messageSchema);
