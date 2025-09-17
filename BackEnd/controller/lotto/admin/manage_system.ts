import express from "express";
import { resetSystem, simulateSystem } from "../../../models/system";
export const router = express.Router();

router.post("/", async (req: any, res) => {
	try {
		const permission: string = req?.auth.role;
		const type: string = req?.body.type;

		if (permission !== "admin") {
			return res.status(403).json({
				success: false,
				message: "Forbidden",
			});
		}

		let msg;
		if (type === "reset") {
			msg = await resetSystem();
		} else if (type === "simulate") {
			msg = await simulateSystem();
		} else {
			return res.status(400).json({
				success: false,
				message: "Bad Request",
			});
		}

		if (msg === "Internal Server Error") {
			return res.status(500).json({
				success: false,
				message: msg,
			});
		}

		return res.status(200).json({
			success: true,
			message: `${msg} สำเร็จ!`,
		});
	} catch (error) {
		console.error("เกิดข้อผิดพลาด:", error);
		return res.status(500).json({
			success: false,
			message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
		});
	}
});
