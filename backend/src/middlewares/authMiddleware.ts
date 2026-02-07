import { NextFunction, Request, Response } from "express";
import jwt from 'jsonwebtoken';
import mongoose from "mongoose";

import { IUser, User } from "../models/User";

interface AuthRequest extends Request {
    user?: mongoose.Document<unknown, any, IUser> & IUser;
}

export const protect = async (req: AuthRequest, res: Response, next: NextFunction) => {
    let token;

    if (req.headers.authorization && req.headers.authorization?.startsWith("Bearer")) {
        try {
            token = req.headers.authorization.split(" ")[1];

            const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET!) as { id: string };

            const user = await User.findById(decoded.id).select("-password");

            if (!user) {
                return res.status(401).json({ success: false, message: "User no longer exists." });
            }

            req.user = user;
            next();
        } catch (error) {
            if (error instanceof jwt.TokenExpiredError) {
                return res.status(401).json({
                    success: false,
                    code: "TOKEN_EXPIRED",
                    message: "Token expired"
                });
            }
            return res.status(401).json({
                success: false,
                message: "Token failed"
            });
        }
    }

    if (!token) {
        return res.status(401).json({
            success: false,
            message: "Not authorized, no token provided."
        });
    }
};