import { Router } from 'express';

import authRouter from './routes/auth';
import userRouter from './routes/users';
import utilsRouter from './routes/utils';
import privacySettingsRouter from './routes/privacySettings';
import notificationSettingsRouter from './routes/notificationSettings';

const routesRouter: Router = Router();

routesRouter.use('/auth', authRouter);
routesRouter.use('/notification-settings', notificationSettingsRouter);
routesRouter.use('/privacy-settings', privacySettingsRouter);
routesRouter.use('/users', userRouter);
routesRouter.use('/utils', utilsRouter);

export default routesRouter;
