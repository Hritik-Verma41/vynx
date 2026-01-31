import express, { type Request, type Response } from 'express';

const app = express();
const PORT = 8000;

app.use(express.json());

app.get('/', (req: Request, res: Response) => {
    res.json({ message: "Hello from Vynx backend" });
});

app.listen(PORT, () => {
    console.log(`⚡️[server]: Vynx server is running at http://localhost:${PORT}`)
});
