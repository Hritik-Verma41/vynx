import { model, Schema, Types } from "mongoose";

export interface IContact {
    owner: Types.ObjectId;
    contactUser: Types.ObjectId;
    alias?: string | null;
    source: "phone" | "qr";
    isBlocked: boolean;
    relationStatus: "pending_incoming" | "pending_outgoing" | "accepted" | "rejected";
    requestedBy?: Types.ObjectId | null;
}

const contactSchema = new Schema<IContact>(
    {
        owner: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        contactUser: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
        alias: { type: String, default: null, trim: true },
        source: { type: String, enum: ["phone", "qr"], required: true },
        isBlocked: { type: Boolean, default: false },
        relationStatus: {
            type: String,
            enum: ["pending_incoming", "pending_outgoing", "accepted", "rejected"],
            default: "accepted",
            index: true
        },
        requestedBy: {
            type: Schema.Types.ObjectId,
            ref: "User",
            default: null
        },
    },
    { timestamps: true }
);

contactSchema.index({ owner: 1, contactUser: 1 }, { unique: true });

export const Contact = model<IContact>("Contact", contactSchema);
