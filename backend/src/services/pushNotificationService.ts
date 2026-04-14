import admin from "firebase-admin";

import { NotificationSettings } from "../models/NotificationSettings";
import { User } from "../models/User";

let initialized = false;

function getServiceAccount() {
    const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const rawBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

    if (rawJson) {
        try {
            return JSON.parse(rawJson);
        } catch {
            return null;
        }
    }

    if (rawBase64) {
        try {
            return JSON.parse(Buffer.from(rawBase64, "base64").toString("utf8"));
        } catch {
            return null;
        }
    }

    return null;
}

function ensureFirebaseApp() {
    if (initialized) return true;

    const serviceAccount = getServiceAccount();
    if (!serviceAccount) return false;

    try {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        initialized = true;
        return true;
    } catch {
        return false;
    }
}

async function notificationsEnabled(userId: string): Promise<boolean> {
    const settings = await NotificationSettings.findOne({ user: userId }).select("enabled");
    if (!settings) return true;
    return Boolean(settings.enabled);
}

async function removeBadTokens(userId: string, tokens: string[]) {
    if (tokens.length === 0) return;
    await User.findByIdAndUpdate(
        userId,
        { $pull: { fcmTokens: { $in: tokens } } },
        { new: true }
    );
}

export async function sendPushToUser(
    userId: string,
    payload: {
        title: string;
        body: string;
        data?: Record<string, string>;
    }
) {
    try {
        if (!ensureFirebaseApp()) return;

        const enabled = await notificationsEnabled(userId);
        if (!enabled) return;

        const user = await User.findById(userId).select("fcmTokens");
        const tokens = (user?.fcmTokens ?? []).filter((token) => token.trim().length > 0);
        if (tokens.length === 0) return;

        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: payload.data,
        });

        if (response.failureCount === 0) return;

        const invalidTokens: string[] = [];
        for (let i = 0; i < response.responses.length; i += 1) {
            const r = response.responses[i];
            if (r.success) continue;
            const code = r.error?.code ?? "";
            if (
                code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token"
            ) {
                invalidTokens.push(tokens[i]);
            }
        }
        await removeBadTokens(userId, invalidTokens);
    } catch {
        // Keep core contact flow non-blocking if push fails
        return;
    }
}

export async function sendContactRequestPush(
    recipientUserId: string,
    senderName: string
) {
    await sendPushToUser(recipientUserId, {
        title: "New contact request",
        body: `${senderName} sent you a contact request.`,
        data: { type: "contact_request_received" },
    });
}

export async function sendContactAcceptedPush(
    recipientUserId: string,
    actorName: string
) {
    await sendPushToUser(recipientUserId, {
        title: "Request accepted",
        body: `${actorName} accepted your contact request.`,
        data: { type: "contact_request_accepted" },
    });
}

export async function sendContactRejectedPush(
    recipientUserId: string,
    actorName: string
) {
    await sendPushToUser(recipientUserId, {
        title: "Request declined",
        body: `${actorName} declined your contact request.`,
        data: { type: "contact_request_rejected" },
    });
}
