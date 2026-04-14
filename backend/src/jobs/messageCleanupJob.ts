import cron from "node-cron";
import cloudinary from "../config/cloudinary";
import { Message } from "../models/Message";

async function destroyCloudinaryFile(publicId?: string | null) {
    if (!publicId) return;
    try {
        await cloudinary.uploader.destroy(publicId, { resource_type: "auto" });
    } catch {
        // non-blocking
    }
}

async function cleanupDeliveredTextMessages() {
    const deliveredTexts = await Message.find({
        kind: "text",
        deleteWhenDelivered: true,
        deliveredAt: { $ne: null },
    }).select("_id");

    if (deliveredTexts.length === 0) return 0;

    const ids = deliveredTexts.map((m) => m._id);
    await Message.deleteMany({ _id: { $in: ids } });

    return ids.length;
}

async function cleanupDownloadedFileMessages() {
    const downloadedFiles = await Message.find({
        kind: "file",
        downloadedAt: { $ne: null },
    }).select("_id file.publicId");

    if (downloadedFiles.length === 0) return 0;

    for (const msg of downloadedFiles) {
        await destroyCloudinaryFile(msg.file?.publicId);
    }

    const ids = downloadedFiles.map((m) => m._id);
    await Message.deleteMany({ _id: { $in: ids } });

    return ids.length;
}

export function startMessageCleanupJob() {
    const timezone = process.env.CRON_TZ || "Asia/Kolkata";

    cron.schedule(
        "0 0 * * *",
        async () => {
            try {
                const textDeleted = await cleanupDeliveredTextMessages();
                const fileDeleted = await cleanupDownloadedFileMessages();

                console.log(
                    `[cleanup] done @00:00 (${timezone} | text=${textDeleted}, files=${fileDeleted})`
                );
            } catch (error) {
                console.error("[cleanup] failed:", (error as Error).message);
            }
        },
        { timezone }
    );
}
