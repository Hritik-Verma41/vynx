import express, { Request, Response } from 'express';
import cloudinary from '../config/cloudinary'; 

const utilsRouter = express.Router();

utilsRouter.post('/delete-image', async (req: Request, res: Response) => {
  const { publicId } = req.body;

  if (!publicId) {
    return res.status(400).json({ success: false, message: "publicId required" });
  }

  try {
    const result = await cloudinary.uploader.destroy(publicId);

    if (result.result === 'ok') {
      return res.status(200).json({ success: true });
    }
    
    return res.status(404).json({ success: false, details: result.result });
  } catch (error) {
    console.error("[Cloudinary Error]:", error);
    return res.status(500).json({ success: false });
  }
});

export default utilsRouter;
