import { Router } from 'express';
import authRouter from './routes/auth';

const routesRouter: Router = Router();

routesRouter.use('/auth', authRouter);

export default routesRouter;
