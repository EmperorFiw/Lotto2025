import express from "express";
import { WonPrize } from "../../models/lotto";

export const router = express.Router();

router.post("/", async (req: any, res) => {
	try {
		const username: string | undefined = req.auth?.username;
		const number: string = req.body.number;

		if (!number || !username) {
			return res.status(400).json({
				success: false,
				message: "ข้อมูลไม่ครบ",
			});
		}

		const message = await WonPrize(username, number);

		// success
		const success = !message.includes("เสียใจ");

		return res.status(200).json({
			success,
			message,
		});
	} catch (error) {
		console.error("เกิดข้อผิดพลาดในการตรวจลอตเตอรี่:", error);
		return res.status(500).json({
			success: false,
			message: "Internal Server Error!",
		});
	}
});
