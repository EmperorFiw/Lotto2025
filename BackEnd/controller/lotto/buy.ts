import express from "express";
import { purchaseLotto } from "../../models/lotto";

export const router = express.Router();

router.post("/", async (req: any, res) => {
    try {
        const username = req.auth?.username;
        const { numbers } = req.body;

        if (!numbers || !Array.isArray(numbers) || numbers.length === 0) {
            return res.status(400).json({
                success: false,
                message: "กรุณาส่งเลขล็อตเตอรี่เป็น array",
            });
        }

        const result = await purchaseLotto(username, numbers);

        if (!result.success) {
            return res.status(400).json(result);
        }

        return res.json(result);
    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการซื้อล็อตเตอรี่:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
