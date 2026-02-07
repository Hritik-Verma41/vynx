import { NextFunction, Request, Response } from "express";
import jwt from 'jsonwebtoken';

import { User } from "../models/User";

export const protect = async (req: Request, res: Response, next: NextFunction) => {
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
            console.log("Auth Middleware Error: ", error);
            return res.status(401).json({
                success: false,
                message: "Not authorized, token failed."
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