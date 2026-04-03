import { Document, model, Schema } from "mongoose";

export interface INotificationSettings extends Document {
    user: Schema.Types.ObjectId;
    enabled: boolean;
    messagePreview: boolean;
    sound: boolean;
    vibrate: boolean;
    calls: boolean;
    updatedAt: Date;
}

const notificationSettingsSchema = new Schema<INotificationSettings>(
    {
        user: { type: Schema.Types.ObjectId, ref: "User", required: true, unique: true },
        enabled: { type: Boolean, default: true },
        messagePreview: { type: Boolean, default: true },
        sound: { type: Boolean, default: true },
        vibrate: { type: Boolean, default: true },
    },
    { timestamps: true }
);

export const NotificationSettings = model<INotificationSettings>(
    "NotificationSettings",
    notificationSettingsSchema
);
