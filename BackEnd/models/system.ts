import { pool } from "../database/db";

export async function resetSystem() {
	try {
		await pool.query("DELETE FROM lotto");
		await pool.query("DELETE FROM lotto_results");
		await pool.query("DELETE FROM users WHERE role != 'admin'");
		await pool.query("DELETE FROM history");

		return "รีเซ็ตระบบ";
	} catch (error) {
		console.error("เกิดข้อผิดพลาด:", error);
		return "Internal Server Error";
	}
}


export async function simulateSystem(count = 200): Promise<string> {
    try {
      const MAX = 1_000_000; // จำนวนเลข 6 หลักทั้งหมด 000000..999999
  
      // อ่านเลขที่มีอยู่ใน DB
      const [existingRows]: any = await pool.query("SELECT lotto_number FROM lotto");
      const existingSet = new Set<string>(
        existingRows.map((r: any) => String(r.lotto_number).padStart(6, "0"))
      );
  
      const remainingSpace = MAX - existingSet.size;
      if (remainingSpace <= 0) {
        return `ไม่สามารถสร้างเลขใหม่ได้อีกแล้ว ฐานข้อมูลมีเลขครบ ${MAX} หมายเลข`;
      }
      if (remainingSpace < count) {
        return `ไม่สามารถสร้าง ${count} หมายเลขได้ (เหลือพื้นที่เพียง ${remainingSpace} หมายเลข)`;
      }
  
      const insertedNumbers: string[] = [];
      const maxRounds = 1000; // guard กัน loop ไม่รู้จบในกรณีพิเศษ
      let round = 0;
  
      while (insertedNumbers.length < count) {
        round++;
        if (round > maxRounds) {
          throw new Error("เกินจำนวนรอบที่กำหนด ระงับการทำงาน");
        }
  
        const need = count - insertedNumbers.length;
        // สุ่มชุด candidate ที่ไม่ชนกับ existingSet
        const candidates = new Set<string>();
        while (candidates.size < need) {
          const n = Math.floor(Math.random() * MAX);
          const s = String(n).padStart(6, "0");
          if (!existingSet.has(s) && !candidates.has(s)) {
            candidates.add(s);
          }
        }
        const candidateArray = Array.from(candidates);
        const values = candidateArray.map(n => [n]);
  
        // Insert แบบ IGNORE เผื่อมีคนอื่นแทรกขึ้นมาพร้อมกัน (จะไม่เกิด error)
        const [result]: any = await pool.query(
          "INSERT IGNORE INTO lotto (lotto_number) VALUES ?",
          [values]
        );
  
        // เช็กเลขที่มีอยู่ตอนนี้ใน DB ของชุด candidate
        const [rowsSel]: any = await pool.query(
          "SELECT lotto_number FROM lotto WHERE lotto_number IN (?)",
          [candidateArray]
        );
  
        // หาว่าเลขใดใน rowsSel เป็นเลขใหม่ (ที่ยังไม่อยู่ใน existingSet ก่อนหน้านี้)
        const prevExisting = new Set(existingSet); // snapshot ก่อนเพิ่ม
        for (const r of rowsSel) {
          const num = String(r.lotto_number).padStart(6, "0");
          if (!prevExisting.has(num)) {
            insertedNumbers.push(num);
            existingSet.add(num);
          }
        }
  
      }
  
      console.log("simulateSystem inserted:", insertedNumbers.length, "numbers");
      // console.log(insertedNumbers);
  
      return `จำลองระบบสำเร็จ สร้างเลข ${insertedNumbers.length} รายการ`;
    } catch (error) {
      console.error("simulateSystem error:", error);
      return "Internal Server Error";
    }
  }