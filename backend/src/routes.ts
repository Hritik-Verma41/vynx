import { Router } from 'express';

import authRouter from './routes/auth';
import userRouter from './routes/users';
import utilsRouter from './routes/utils';

const routesRouter: Router = Router();

routesRouter.use('/auth', authRouter);
routesRouter.use('/users', userRouter);
routesRouter.use('/utils', utilsRouter);

export default routesRouter;
