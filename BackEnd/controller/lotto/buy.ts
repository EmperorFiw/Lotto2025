import express from "express";
import { purchaseLotto } from "../../models/lotto";
export const router = express.Router();
const LOTTO_PRICE: number = process.env.LOTTO_PRICE ? parseInt(process.env.LOTTO_PRICE) : 80;

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

        const purchased = await purchaseLotto(username, numbers);

        const totalPrice = purchased.length * LOTTO_PRICE;

        return res.json({
            success: true,
            purchasedCount: purchased.length,
            totalPrice: totalPrice,
            purchasedNumbers: purchased
        });
    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการซื้อล็อตเตอรี่:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
