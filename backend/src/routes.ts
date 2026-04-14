import { Router } from 'express';

import authRouter from './routes/auth';
import userRouter from './routes/users';
import utilsRouter from './routes/utils';
import privacySettingsRouter from './routes/privacySettings';
import notificationSettingsRouter from './routes/notificationSettings';
import dataUsageSettingsRouter from './routes/dataUsageSettings';
import conversationsRouter from './routes/conversations';
import contactsRouter from './routes/contacts';

const routesRouter: Router = Router();

routesRouter.use('/auth', authRouter);
routesRouter.use('/contacts', contactsRouter);
routesRouter.use('/conversations', conversationsRouter);
routesRouter.use('/notification-settings', notificationSettingsRouter);
routesRouter.use('/privacy-settings', privacySettingsRouter);
routesRouter.use('/data-usage-settings', dataUsageSettingsRouter);
routesRouter.use('/users', userRouter);
routesRouter.use('/utils', utilsRouter);

export default routesRouter;
