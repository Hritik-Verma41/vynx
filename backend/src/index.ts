import express, { type Request, type Response } from 'express';
import routesRouter from './routes';

const app = express();
const PORT = 8000;

app.use(express.json({ limit: '50mb' }));

app.get('/', (req: Request, res: Response) => {
    res.json({ message: "Hello from Vynx backend" });
});

app.use('/api', routesRouter);

app.post('/api/auth/sign-up', (req: Request, res: Response) => {
    console.log(req.body);
    res.json(req.body);
})

app.listen(PORT, () => {
    console.log(`⚡️[server]: Vynx server is running at http://localhost:${PORT}`)
});
