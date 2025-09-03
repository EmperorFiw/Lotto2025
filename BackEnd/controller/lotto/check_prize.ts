import express from "express";
import { pool } from "../../database/db";
import { WonPrize } from "../../models/lotto";

export const router = express.Router();

router.post("/", async (req: any, res) => {
    try {
		const username = req.auth?.username;
        const number: string = req.body.number;
        if (!number || !username) {
            return res.status(400).json({
                success: false,
                message: "ข้อมูลไม่ครบ",
            });
        }

        // ตรวจสอบเลขจากตาราง lotto_results
        const [rows]: any = await pool.query(
            "SELECT prize_name, prize_amount FROM lotto_results WHERE number = ?",
            [number]
        );

        if (rows.length > 0) {
            const prize = rows[0];
            return res.status(200).json({
                success: true,
                message: `ยินดีด้วย! เลข ${number} ถูกรางวัล ${prize.prize_name} จำนวน ${prize.prize_amount} บาท`,
            });
        }
		else
		{
			// ไม่ถูกรางวัล
			await WonPrize(username, number, false);
			return res.status(200).json({
				success: false,
				message: `เสียใจด้วย เลข ${number} ไม่ถูกรางวัล`,
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
