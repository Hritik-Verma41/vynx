import { model, Schema } from 'mongoose';

export interface IUser {
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    password?: string | null;
    profileImage: string;
    gender: 'male' | 'female' | 'other';
    firebaseUid: string;
    googleUid?: string;
    facebookUid?: string;
    providers: ('local' | 'google' | 'facebook' | 'phone')[];
    refreshToken?: string | null;
}

const userSchema = new Schema<IUser>({
    firstName: { type: String, required: true, trim: true },
    lastName: { type: String, required: false, trim: false },
    email: { type: String, required: true, unique: true, lowercase: true },
    phoneNumber: { type: String, required: true, unique: true },
    password: { type: String, default: null },
    profileImage: { type: String, required: true },
    gender: { type: String, enum: ['male', 'female', 'other'], required: true },
    firebaseUid: { type: String, required: true, unique: true },
    googleUid: { type: String, sparse: true, default: null },
    facebookUid: { type: String, sparse: true, default: null },
    providers: [{
        type: String,
        enum: ['local', 'google', 'facebook', 'phone'],
        required: true
    }],
    refreshToken: { type: String, default: null }
}, { timestamps: true });

export const User = model<IUser>('User', userSchema);
