import express from "express";
import { RowDataPacket } from 'mysql2';
import { pool } from "../../database/db";

export const router = express.Router();

// Interface สำหรับผลลัพธ์ลอตเตอรี่
interface LottoResult extends RowDataPacket {
  prize_name: string;
  prize_amount: string;
  lotto_number: string;
}

router.get("/", async (req, res) => {
  try {
    // ดึงข้อมูลจากฐานข้อมูล
    const [rows] = await pool.query<LottoResult[]>(
      "SELECT prize_name, prize_amount, lotto_number FROM lotto_results ORDER BY " +
      "CASE " +
      "  WHEN prize_name = 'รางวัลที่ 1' THEN 1 " +
      "  WHEN prize_name = 'รางวัลที่ 2' THEN 2 " +
      "  WHEN prize_name = 'รางวัลที่ 3' THEN 3 " +
      "  WHEN prize_name = 'เลขท้าย 3 ตัว' THEN 4 " +
      "  WHEN prize_name = 'เลขท้าย 2 ตัว' THEN 5 " +
      "END"
    );

    // แปลงข้อมูลให้ตรงกับรูปแบบที่ Frontend ต้องการ
    const lottoResults = rows.map(row => ({
      title: row.prize_name,
      amount: `รางวัลละ ${parseInt(row.prize_amount).toLocaleString('th-TH')} บาท`,
      number: row.lotto_number
    }));

    return res.status(200).json({
      success: true,
      lotto_results: lottoResults
    });

  } catch (error) {
    console.error("เกิดข้อผิดพลาดในการดึงผลลอตเตอรี่:", error);
    
    // หากเกิดข้อผิดพลาดหรือยังไม่มีข้อมูลในฐานข้อมูล
    return res.status(200).json({
      success: true,
      lotto_results: [
        {'title': 'รางวัลที่ 1', 'amount': 'รางวัลละ 6,000,000 บาท', 'number': ''},
        {'title': 'รางวัลที่ 2', 'amount': 'รางวัลละ 200,000 บาท', 'number': ''},
        {'title': 'รางวัลที่ 3', 'amount': 'รางวัลละ 80,000 บาท', 'number': ''},
        {'title': 'เลขท้าย 3 ตัว', 'amount': 'รางวัลละ 4,000 บาท', 'number': ''},
        {'title': 'เลขท้าย 2 ตัว', 'amount': 'รางวัลละ 2,000 บาท', 'number': ''},
      ],
    });
  }
});