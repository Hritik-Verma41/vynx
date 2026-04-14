import { model, Schema, Types } from "mongoose";

export interface IConversation {
    members: Types.ObjectId[];
    membersKey?: string | null;
    type: "direct" | "group";
    name?: string | null;
    description?: string | null;
    avatar?: string | null;
    createdBy?: Types.ObjectId | null;
    admins: Types.ObjectId[];
    lastMessage: string | null;
    lastMessageType:
    | "text"
    | "file"
    | "image"
    | "video"
    | "audio"
    | "location"
    | "contact"
    | "document"
    | "poll"
    | "event"
    | null;
    lastMessageAt: Date | null;
}

const conversationSchema = new Schema<IConversation>(
    {
        members: [
            { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        ],
        membersKey: { type: String, default: null, index: true, sparse: true },
        type: { type: String, enum: ["direct", "group"], required: true, default: "direct", index: true },
        name: { type: String, default: null, trim: true },
        description: { type: String, default: null, trim: true },
        avatar: { type: String, default: null },
        createdBy: { type: Schema.Types.ObjectId, ref: "User", default: null },
        admins: [{ type: Schema.Types.ObjectId, ref: "User", required: true }],
        lastMessage: { type: String, default: null },
        lastMessageType: {
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
                null,
            ],
            default: null,
        },
        lastMessageAt: { type: Date, default: null },
    },
    { timestamps: true }
);

conversationSchema.pre("validate", function (next) {
    const doc = this as any;
    if (Array.isArray(doc.members) && doc.members.length > 0 && doc.type === "direct") {
        const sorted = doc.members.map((id: Types.ObjectId) => id.toString()).sort();
        doc.membersKey = sorted.join(":");
    } else if (doc.type === "group") {
        doc.membersKey = null;
    }

    if (Array.isArray(doc.members) && doc.members.length > 0) {
        const memberSet = new Set(doc.members.map((id: Types.ObjectId) => id.toString()));
        const admins = Array.isArray(doc.admins) ? doc.admins : [];
        const normalizedAdmins = admins.filter(
            (id: Types.ObjectId) => memberSet.has(id.toString())
        );
        if (normalizedAdmins.length === 0) {
            const firstMember = doc.members[0];
            doc.admins = [firstMember];
        } else {
            doc.admins = normalizedAdmins;
        }
    }

    next();
});

conversationSchema.index(
    { membersKey: 1 },
    { unique: true, partialFilterExpression: { type: "direct", membersKey: { $type: "string" } } }
);
conversationSchema.index({ updatedAt: -1 });

export const Conversation = model<IConversation>("Conversation", conversationSchema);
