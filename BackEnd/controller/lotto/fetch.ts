import express from "express";
import { fetchLotto } from "../../models/lotto";
export const router = express.Router();

router.get("/", async (req, res) => {
    try {
        const lottoResults = await fetchLotto();

        return res.json({
            success: true,
            numbers: lottoResults,
        });
    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการดึงล็อตเตอรี่:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
