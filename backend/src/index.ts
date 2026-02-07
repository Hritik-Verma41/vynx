import cors from 'cors';
import dotenv from 'dotenv';
import express, { Application, Request, Response } from 'express';

import routesRouter from './routes';
import connectDB from './config/mongodb';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 8000;

connectDB();

app.use(cors({
    exposedHeaders: ['Authorization', 'x-refresh-token']
}));
app.use(express.json({ limit: '50mb' }));

app.use('/api', routesRouter);

app.get('/', (req: Request, res: Response) => {
    res.json({ message: "Hello from Vynx backend" });
});

app.listen(PORT, () => {
    console.log(`⚡️[server]: Vynx server is running at http://localhost:${PORT}`)
});
