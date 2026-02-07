import { Router, Request, Response } from "express";
import { Document } from 'mongoose';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

import { IUser, User } from "../models/User";
import { generateTokens } from "../utils/generateToken";
import { protect } from "../middlewares/authMiddleware";

const authRouter: Router = Router();

const sendAuthResponse = async (user: Document & IUser, res: Response, statusCode: number = 200) => {
    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    user.refreshToken = refreshToken;
    await user.save();

    res.set('Authorization', `Bearer ${accessToken}`);
    res.set('x-refresh-token', refreshToken);

    return res.status(statusCode).json({
        success: true,
        user: {
            id: user._id,
            firstName: user.firstName,
            lastName: user.lastName,
            profileImage: user.profileImage
        }
    });
};

authRouter.post('/sign-up', async (req: Request, res: Response) => {
    try {
        const {
            firebaseUid, email, phoneNumber, firstName,
            lastName, profileImage, gender, providers, password,
            googleUid, facebookUid
        } = req.body;

        const requiredFields = ['firebaseUid', 'email', 'phoneNumber', 'firstName', 'profileImage', 'gender'];
        for (const field of requiredFields) {
            if (!req.body[field]) {
                return res.status(400).json({
                    success: false,
                    message: `Field '${field}' is mandatory.`
                });
            }
        }

        if (!['male', 'female', 'other'].includes(gender)) {
            return res.status(400).json({
                success: false,
                message: "Invalid gender value."
            });
        }

        let existingUser = await User.findOne({
            $or: [{ firebaseUid }, { email }, { phoneNumber }]
        });

        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: "User with this email, phone, or Firebase ID already exists."
            });
        }

        let hashedPassword = null;

        if (password && password.trim() !== "") {
            const salt = await bcrypt.genSalt(10);
            hashedPassword = await bcrypt.hash(password, salt);
        }

        const newUser = new User({
            firebaseUid,
            email,
            phoneNumber,
            firstName,
            lastName,
            profileImage,
            gender,
            password: hashedPassword,
            googleUid: googleUid || null,
            facebookUid: facebookUid || null,
            providers: providers || ['phone']
        });

        return await sendAuthResponse(newUser, res, 201);
    } catch (error) {
        console.log(`Signup error: ${error}`);
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

authRouter.post('/login', async (req: Request, res: Response) => {
    try {
        const { email, password, googleUid, facebookUid, provider } = req.body;

        if (provider === 'google') {
            if (!googleUid) {
                return res.status(400).json({
                    success: false,
                    message: "Google UID is required."
                });
            }

            const user = await User.findOne({ googleUid });
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: "No account linked to this Google account."
                });
            }

            return await sendAuthResponse(user, res);
        }

        if (provider === 'facebook') {
            if (!facebookUid) {
                return res.status(400).json({
                    success: false,
                    message: "Facebook UID is required."
                });
            }

            const user = await User.findOne({ facebookUid });
            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: "No account linked to this Facebook account."
                });
            }

            return await sendAuthResponse(user, res);
        }

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and password are required."
            });
        }

        const user = await User.findOne({ email });
        if (!user || !user.password) {
            return res.status(401).json({
                success: false,
                message: "Invalid credentials or account uses a different login method."
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid credentials."
            });
        }

        return await sendAuthResponse(user, res);
    } catch (error) {
        console.log(`Login error: ${error}`);
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

authRouter.post('/logout', async (req: Request, res: Response) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: "Token required."
            });
        }

        const user = await User.findOneAndUpdate(
            { refreshToken },
            { refreshToken: null }
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "Session not found."
            });
        }

        res.json({
            success: true,
            message: "Logged out successfully."
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

authRouter.post('/refresh-token', async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({
            success: false,
            message: "Refresh token is required!"
        });
    }

    try {
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET!) as { id: string };

        const user = await User.findById(decoded.id);

        if (!user || user.refreshToken !== refreshToken) {
            return res.status(403).json({
                success: false,
                message: "Invalid or expired refresh token"
            });
        }

        const tokens = generateTokens(user._id.toString());

        user.refreshToken = tokens.refreshToken;
        await user.save();

        res.set('Authorization', `Bearer ${tokens.accessToken}`);
        res.set('x-refresh-token', tokens.refreshToken);

        res.json({ success: true });
    } catch (error: any) {
        console.log(`Refresh-Token error: ${error.message}`);

        if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
            return res.status(403).json({ success: false, message: "Session expired. Please login again." });
        }

        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

authRouter.get('/profile', protect, async (req: Request, res: Response) => {
    try {
        const userRequest = req as any;
        if (!userRequest.user) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        res.json({
            success: true,
            user: userRequest.user
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: "Internal Server Error"
        });
    }
});

export default authRouter;
