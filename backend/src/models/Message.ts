import { model, Schema, Types } from "mongoose";

export interface IMessageFile {
    url: string,
    publicId?: string | null;
    fileName: string,
    mimeType: string,
    sizeBytes: number;
}

export interface IMessageLocation {
    latitude: number;
    longitude: number;
    label?: string | null;
}

export interface IMessageContact {
    name: string;
    phoneNumber: string;
}

export interface IMessagePollOption {
    id: string;
    text: string;
}

export interface IMessagePollVote {
    userId: Types.ObjectId;
    optionId: string;
    votedAt: Date;
}

export interface IMessagePoll {
    question: string;
    options: IMessagePollOption[];
    multipleChoice: boolean;
    closesAt?: Date | null;
    votes: IMessagePollVote[];
}

export interface IMessageEvent {
    title: string;
    notes?: string | null;
    startAt: Date;
    endAt?: Date | null;
    locationLabel?: string | null;
}

export interface IMessage {
    conversation: Types.ObjectId;
    sender: Types.ObjectId;
    recipient?: Types.ObjectId | null;
    recipients: Types.ObjectId[];
    kind:
    | "text"
    | "file"
    | "image"
    | "video"
    | "audio"
    | "location"
    | "contact"
    | "document"
    | "poll"
    | "event";
    text?: string | null;
    file?: IMessageFile | null;
    location?: IMessageLocation | null;
    sharedContact?: IMessageContact | null;
    poll?: IMessagePoll | null;
    event?: IMessageEvent | null;

    deliveredAt?: Date | null;
    readAt?: Date | null;
    downloadedAt?: Date | null;
    deliveredTo: Types.ObjectId[];
    readBy: Types.ObjectId[];
    downloadedBy: Types.ObjectId[];

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
        recipient: { type: Schema.Types.ObjectId, ref: "User", default: null, index: true },
        recipients: [{ type: Schema.Types.ObjectId, ref: "User", required: true, index: true }],
        kind: {
            type: String,
            enum: [
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
            ],
            required: true,
            index: true
        },

        text: { type: String, default: null },
        file: { type: messageFileSchema, default: null },
        location: {
            type: {
                latitude: { type: Number, required: true },
                longitude: { type: Number, required: true },
                label: { type: String, default: null },
            },
            _id: false,
            default: null,
        },
        sharedContact: {
            type: {
                name: { type: String, required: true },
                phoneNumber: { type: String, required: true },
            },
            _id: false,
            default: null,
        },
        poll: {
            type: {
                question: { type: String, required: true },
                options: [
                    {
                        _id: false,
                        id: { type: String, required: true },
                        text: { type: String, required: true },
                    }
                ],
                multipleChoice: { type: Boolean, default: false },
                closesAt: { type: Date, default: null },
                votes: [
                    {
                        _id: false,
                        userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
                        optionId: { type: String, required: true },
                        votedAt: { type: Date, required: true },
                    }
                ],
            },
            _id: false,
            default: null,
        },
        event: {
            type: {
                title: { type: String, required: true },
                notes: { type: String, default: null },
                startAt: { type: Date, required: true },
                endAt: { type: Date, default: null },
                locationLabel: { type: String, default: null },
            },
            _id: false,
            default: null,
        },

        deliveredAt: { type: Date, default: null, index: true },
        readAt: { type: Date, default: null },
        downloadedAt: { type: Date, default: null, index: true },
        deliveredTo: [{ type: Schema.Types.ObjectId, ref: "User", default: [] }],
        readBy: [{ type: Schema.Types.ObjectId, ref: "User", default: [] }],
        downloadedBy: [{ type: Schema.Types.ObjectId, ref: "User", default: [] }],

        deleteWhenDelivered: { type: Boolean, default: true, index: true },
    },
    { timestamps: true }
);

messageSchema.index({ conversation: 1, createdAt: -1 });
messageSchema.index({ recipients: 1, deliveredAt: 1 });
messageSchema.index({ kind: 1, deleteWhenDelivered: 1 });

export const Message = model<IMessage>("Message", messageSchema);
