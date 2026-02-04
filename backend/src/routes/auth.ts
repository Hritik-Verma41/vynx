import { Router, Request, Response } from "express";

const authRouter: Router = Router();

authRouter.post('/sign-up', (req: Request, res: Response) => {
    console.log(req.body);
    res.json(req.body);
})

export default authRouter;