import { Document, model, Schema } from "mongoose";

export interface IDataUsageSettings extends Document {
    user: Schema.Types.ObjectId;
    dataSaver: boolean;
    mobilePhotos: boolean;
    mobileVideos: boolean;
    mobileAudio: boolean;
    mobileDocuments: boolean;
    wifiPhotos: boolean;
    wifiVideos: boolean;
    wifiAudio: boolean;
    wifiDocuments: boolean;
    roamingPhotos: boolean;
    roamingVideos: boolean;
    roamingAudio: boolean;
    roamingDocuments: boolean;
    updatedAt: Date;
}

const dataUsageSettingsSchema = new Schema<IDataUsageSettings>(
    {
        user: { type: Schema.Types.ObjectId, ref: "User", required: true, unique: true },
        dataSaver: { type: Boolean, default: false },
        mobilePhotos: { type: Boolean, default: true },
        mobileVideos: { type: Boolean, default: false },
        mobileAudio: { type: Boolean, default: false },
        mobileDocuments: { type: Boolean, default: false },
        wifiPhotos: { type: Boolean, default: true },
        wifiVideos: { type: Boolean, default: true },
        wifiAudio: { type: Boolean, default: true },
        wifiDocuments: { type: Boolean, default: true },
        roamingPhotos: { type: Boolean, default: false },
        roamingVideos: { type: Boolean, default: false },
        roamingAudio: { type: Boolean, default: false },
        roamingDocuments: { type: Boolean, default: false }
    },
    { timestamps: true }
);

export const DataUsageSettings = model<IDataUsageSettings>(
    "DataUsageSettings",
    dataUsageSettingsSchema
);