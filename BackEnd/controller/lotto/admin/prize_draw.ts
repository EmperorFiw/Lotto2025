import express from "express";
import { createLottoResults, fetchLotto, hasBeenDrawn } from "../../../models/lotto";
export const router = express.Router();

router.post("/", async (req: any, res) => {
    try {
        const permission: string = req?.auth.role;
        if (permission !== "admin") {
            return res.status(403).json({
                success: false,
                message: "Forbidden: Only admin can perform this action"
            });
        }

        const type = req?.body?.prize_draw_type;
        if (!type) {
            return res.status(400).json({
                success: false,
                message: "Missing required parameter: prize_draw_type"
            });
        }

        // ตรวจสอบว่ามีการจับรางวัลแล้วหรือยัง
        const drawn = await hasBeenDrawn();
        if (drawn) {
            return res.status(400).json({
                success: false,
                message: "รางวัลถูกจับไปแล้ว ไม่สามารถจับซ้ำได้"
            });
        }

        const lottoResults = await fetchLotto(type);
        
        if (type === "sold")
        {
            if (lottoResults.length < 5) {
                return res.status(400).json({
                    success: false,
                    message: "ตัวเลขที่ขายแล้วยังไม่ครบ 5 ชุด"
                });
            }
        }

        // ออกรางวัลทีละรางวัล
        const created = await createLottoResults(lottoResults);
        if (!created) {
            return res.status(500).json({
                success: false,
                message: "เกิดข้อผิดพลาดในการบันทึกรางวัล"
            });
        }

        return res.status(200).json({
            success: true,
            message: "จับรางวัลสำเร็จ",
            numbers: created, // ส่งเลขที่ออกกลับ
        });

    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการจับรางวัลล็อตเตอรี่:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
