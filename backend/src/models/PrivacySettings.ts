import { Document, model, Schema } from "mongoose";

export interface IPrivacySettings extends Document {
    user: Schema.Types.ObjectId;
    lastSeen: 'everyone' | 'contacts' | 'nobody';
    online: 'everyone' | 'contacts' | 'nobody' | 'same_as_last_seen';
    profilePicture: 'everyone' | 'contacts' | 'nobody';
    status: 'everyone' | 'contacts' | 'nobody';
    readReceipts: boolean;
    updatedAt: Date;
}

const privacySettingsScheme = new Schema<IPrivacySettings>({
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    lastSeen: { type: String, enum: ['everyone', 'contacts', 'nobody'], default: 'everyone' },
    online: { type: String, enum: ['everyone', 'contacts', 'nobody', 'same_as_last_seen'], default: 'everyone' },
    profilePicture: { type: String, enum: ['everyone', 'contacts', 'nobody'], default: 'everyone' },
    status: { type: String, enum: ['everyone', 'contacts', 'nobody'], default: 'everyone' },
    readReceipts: { type: Boolean, default: true }
}, { timestamps: true });

export const PrivacySettings = model<IPrivacySettings>('PrivacySetting', privacySettingsScheme);
