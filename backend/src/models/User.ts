import { model, Schema } from 'mongoose';

interface IUser {
    firstName: string;
    lastName: string;
    email: string;
    password?: string; // Optional for SSO users
    profileImage: string;
    googleId?: string;
    facebookId?: string;
    authProviders: ('local' | 'google' | 'facegook')[];
}

const userSchema = new Schema<IUser>({
    firstName: { type: String, required: true },
    lastName: { type: String, required: false },
    email: {type: String, required: true, unique: true},
    password: { type: String },
    profileImage: { type: String, required: true },
    googleId: { type: String, sparse: true },
    facebookId: {type: String, sparse: true},
    authProviders: [{ type: String, enum: ['local', 'google', 'facebook'], required: true }]
}, { timestamps: true });

export const User = model<IUser>('User', userSchema);
