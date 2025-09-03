import express from "express";
import { purchaseLotto } from "../../models/lotto";
import { jwtAuthen } from "../auth/jwt";

export const router = express.Router();

router.post("/", jwtAuthen, async (req:any, res) => {
    try {
        const username = req.auth?.username;
        const numbers: string[] = req.body.numbers;

        if (!username) {
            return res.status(400).json({
                success: false,
                message: "ไม่พบผู้ใช้",
            });
        }

        if (!numbers || numbers.length === 0) {
            return res.status(400).json({
                success: false,
                message: "กรุณาส่งเลขที่จะซื้อ",
            });
        }

        const result = await purchaseLotto(username, numbers);

        return res.status(200).json(result);

    } catch (error) {
        console.error("ซื้อล็อตเตอรี่ล้มเหลว:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์",
        });
    }
});
