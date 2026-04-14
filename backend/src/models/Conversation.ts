import { model, Schema, Types } from "mongoose";

export interface IConversation {
    members: Types.ObjectId[];
    membersKey: string;
    lastMessage: string | null;
    lastMessageType: "text" | "file" | null;
    lastMessageAt: Date | null;
}

const conversationSchema = new Schema<IConversation>(
    {
        members: [
            { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        ],
        membersKey: { type: String, required: true, unique: true, index: true },
        lastMessage: { type: String, default: null },
        lastMessageType: {
            type: String,
            enum: ["text", "file", null],
            default: null,
        },
        lastMessageAt: { type: Date, default: null },
    },
    { timestamps: true }
);

conversationSchema.pre("validate", function (next) {
    const doc = this as any;
    if (Array.isArray(doc.members) && doc.members.length > 0) {
        const sorted = doc.members.map((id: Types.ObjectId) => id.toString()).sort();
        doc.membersKey = sorted.join(":");
    }
    next();
});

conversationSchema.index({ updatedAt: -1 });

export const Conversation = model<IConversation>("Conversation", conversationSchema);
