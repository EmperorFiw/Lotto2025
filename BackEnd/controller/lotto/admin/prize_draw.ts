import express from "express";
import { createLottoResults, fetchLotto, hasBeenDrawn } from "../../../models/lotto";
export const router = express.Router();

router.post("/", async (req: any, res) => {
    try {
        const permission: string = req?.auth.role;
        if (permission !== "admin") 
        {
            return res.status(403).json({
                success: false,
                message: "Forbidden"
            });
        }
        const type = req?.body?.prize_draw_type;
        if (!type) {
            return res.status(400).json({
                success: false,
                message: "Bad Requests"
            });
        }

        const drawn = await hasBeenDrawn();

        if (!drawn) {
            const lottoResults = await fetchLotto(type);

            if (lottoResults.length < 5) {
                return res.status(404).json({
                    success: false,
                    message: "ตัวเลขที่ขายแล้วยังไม่ครบ 5 ชุด"
                });
            }

            const prize: string[] = [];
            
            while (prize.length < 5) {
                const randomIndex = Math.floor(Math.random() * lottoResults.length);
                const number = lottoResults[randomIndex];
            
                if (!prize.includes(number)) {
                    prize.push(number);
                }
            }
            prize[3] = prize[0].slice(-3);
            prize[4] = prize[4].slice(-2);
            if (!await createLottoResults(prize))
            {
                return res.status(500).json({
                    success: false,
                    message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
                });
            }
            console.log("เลขล็อตเตอรี่ที่สุ่มได้:", prize);
            

            return res.status(200).json({
                success: false,
                numbers: prize,
            });
        } else {
            return res.status(200).json({
                success: false,
                message: "คุณออกรางวัลทั้งหมดแล้ว",
            });
        }

    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการดึงล็อตเตอรี่:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
