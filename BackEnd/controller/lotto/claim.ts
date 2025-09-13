import express from "express";
import { pool } from "../../database/db";

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
  
      const [rows]: any = await pool.query(
        `SELECT lr.prize_amount 
         FROM history h
         JOIN lotto_results lr ON h.lotto_number = lr.lotto_number
         WHERE h.lotto_number = ?
           AND h.user_id = (SELECT uid FROM users WHERE username = ?)
           AND h.status = 2`,
        [number, username]
      );
      
  
      if (rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: "ไม่พบลอตเตอรี่ที่สามารถขึ้นเงินได้",
        });
      }
  
      const prizeAmount = rows[0].prize_amount;
  
      // TODO: ตรงนี้อาจมีการ update เงินใน wallet ของ user ด้วย
      await pool.query(
        `UPDATE users SET money = money + ? 
         WHERE username = ?`,
        [prizeAmount, username]
      );
  
      // update history เป็นขึ้นเงินเสร็จสิ้น (status 3 ถ้าต้องการแยก)
      await pool.query(
        `UPDATE history 
         SET status = 3 
         WHERE lotto_number = ? 
           AND user_id = (SELECT uid FROM users WHERE username = ?)`,
        [number, username]
      );
  
      return res.json({
        success: true,
        message: `คุณได้รับเงินจำนวน ${prizeAmount} บาทแล้ว`,
        prize: prizeAmount
      });
    } catch (error) {
      console.error("Error claiming lotto:", error);
      return res.status(500).json({
        success: false,
        message: "เกิดข้อผิดพลาด กรุณาลองใหม่ภายหลัง",
      });
    }
  });
  