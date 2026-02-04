import mongoose from "mongoose"

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/vynx_db');
        console.log(`MongoDB Connected: ${conn.connection.host}`);
        console.log(`Using Database: ${conn.connection.name}`);
    } catch (error) {
        console.error(`Error: ${(error as Error).message}`);
        process.exit(1);
    }
}

export default connectDB;
