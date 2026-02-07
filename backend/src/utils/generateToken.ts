import jwt from 'jsonwebtoken';

export const generateTokens = (userId: string) => {
    const accessSecret = process.env.JWT_ACCESS_SECRET as string;
    const refreshSecret = process.env.JWT_REFRESH_SECRET as string;

    const accessToken = jwt.sign(
        { id: userId },
        accessSecret!,
        { expiresIn: (process.env.ACCESS_TOKEN_EXPIRE || '15m') as any }
    );

    const refreshToken = jwt.sign(
        { id: userId },
        refreshSecret,
        { expiresIn: (process.env.REFRESH_TOKEN_EXPIRE || '7d') as any }
    );

    return { accessToken, refreshToken };
};
