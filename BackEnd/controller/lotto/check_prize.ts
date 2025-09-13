import express from "express";
import { pool } from "../../database/db";
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

		// find number in lotto_results
		const [rows]: any = await pool.query(
			"SELECT prize_name, prize_amount FROM lotto_results WHERE lotto_number = ?",
			[number]
		);

		if (rows.length > 0) {
			const prize = rows[0];
			// call model WonPrize → คืน message
			const result = await WonPrize(username, number, true);

			return res.status(200).json({
				success: true,
				message: result.message, // ส่งข้อความตามเงื่อนไข
				prizeName: prize.prize_name,
				prizeAmount: prize.prize_amount
			});
		} else {
			// call model WonPrize สำหรับเลขไม่ถูกรางวัล
			const result = await WonPrize(username, number, false);

			return res.status(200).json({
				success: false,
				message: result.message,
			});
		}
	} catch (error) {
		console.error("เกิดข้อผิดพลาดในการตรวจลอตเตอรี่:", error);
		return res.status(500).json({
			success: false,
			message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
		});
	}
});
