import { RowDataPacket } from "mysql2/promise";
import { pool } from "../database/db";
const LOTTO_PRICE: number = process.env.LOTTO_PRICE ? parseInt(process.env.LOTTO_PRICE) : 80;


type LottoRow = {
  hid: number | null;
  prize_name: string;
  prize_amount: number;
  lotto_number: string;
};

/**
 * 
 * @param type 
 * @returns 
 */
export async function fetchLotto(type: string = "available"): Promise<string[]> {
  try {
      let sql = "SELECT lotto_number FROM lotto";
      const params: any[] = [];

      if (type !== "all") {
          sql += " WHERE status = ? ORDER BY lotto_number";
          params.push(type);
      }

      const [rows] = await pool.query(sql, params);
      return (rows as any[]).map(row => row.lotto_number);
  } catch (error) {
      console.error("เกิดข้อผิดพลาดในการดึงล็อตเตอรี่จาก DB:", error);
      return [];
  }
}

/**
 * 
 * @param username 
 * @param number 
 * @returns 
 */
export async function WonPrize(
	username: string,
	number: string
): Promise<string> {
	try {
		// แยกเลขท้าย
		const last3 = number.slice(-3);
		const last2 = number.slice(-2);

		const [rows]: any = await pool.query(
			`SELECT h.hid, lr.prize_name, lr.prize_amount, lr.lotto_number
			 FROM history h
			 RIGHT JOIN lotto_results lr
			   ON (lr.lotto_number = h.lotto_number 
			       OR RIGHT(lr.lotto_number, 3) = ? 
			       OR RIGHT(lr.lotto_number, 2) = ?)
			   AND h.user_id = (SELECT uid FROM users WHERE username = ?)
			 WHERE lr.lotto_number = ? 
			    OR RIGHT(lr.lotto_number,3) = ? 
			    OR RIGHT(lr.lotto_number,2) = ?`,
			[last3, last2, username, number, last3, last2]
		);

		if (!rows || rows.length === 0) {
			return `เสียใจด้วย เลข ${number} ไม่ถูกรางวัล`;
		}

		// เลือกแถวที่ตรงที่สุด: 6 หลัก > 3 ตัว > 2 ตัว
		let prizeRow: LottoRow | undefined = rows.find((r: LottoRow) => r.lotto_number === number)
			|| rows.find((r: LottoRow) => r.lotto_number.endsWith(last3))
			|| rows.find((r: LottoRow) => r.lotto_number.endsWith(last2));

		if (!prizeRow) {
			return `เสียใจด้วย เลข ${number} ไม่ถูกรางวัล`;
		}

		const hasHistory = prizeRow.hid != null;

		// อัปเดต status ถ้าเคยซื้อ
		// if (hasHistory) {
		// 	await pool.query(
		// 		"UPDATE history SET status = 2 WHERE lotto_number = ? AND user_id = (SELECT uid FROM users WHERE username = ?)",
		// 		[number, username]
		// 	);
		// }

		// คืนข้อความตามเงื่อนไข
		if (prizeRow.lotto_number === number) {
			return `ยินดีด้วย! เลข ${number} ถูกรางวัล ${prizeRow.prize_name} \nเงินรางวัล ${prizeRow.prize_amount} บาท`;
		} else if (prizeRow.lotto_number.endsWith(last3)) {
			return `ยินดีด้วย! เลข ${number} ถูกรางวัลเลขท้าย 3 ตัว \nเงินรางวัล ${prizeRow.prize_amount} บาท`;
		} else if (prizeRow.lotto_number.endsWith(last2)) {
			return `ยินดีด้วย! เลข ${number} ถูกรางวัลเลขท้าย 2 ตัว \nเงินรางวัล ${prizeRow.prize_amount} บาท`;
		}

		return `เสียใจด้วย เลข ${number} ไม่ถูกรางวัล`;

	} catch (error) {
		console.error("เกิดข้อผิดพลาดในการอัปเดต history:", error);
		return "Internal Server Error!";
	}
}
        
/**
 * 
 * @param username 
 * @param numbers 
 * @returns 
 */
export async function purchaseLotto(
    username: string,
    numbers: string[]
): Promise<{
    success: boolean;
    message: string;
    totalPrice: number;
}> {
    try {
        // ดึง user_id และเงินผู้ใช้
        const [userRows]: any = await pool.query(
            "SELECT uid, money FROM users WHERE username = ?",
            [username]
        );

        if (userRows.length === 0) {
            return {
                success: false,
                message: "ไม่พบผู้ใช้",
                totalPrice: 0,
            };
        }

        const userId = userRows[0].uid;
        const money = userRows[0].money;
        const totalPrice = numbers.length * LOTTO_PRICE;

        // ตรวจสอบว่าเงินพอสำหรับซื้อเลขทั้งหมดหรือไม่
        if (money < totalPrice) {
            return {
                success: false,
                message: `ยอดเงินของคุณไม่เพียงพอ`,
                totalPrice,
            };
        }

        // ตรวจสอบว่าเลขทั้งหมดยัง available
        const [rows]: any = await pool.query(
            "SELECT lotto_number FROM lotto WHERE lotto_number IN (?) AND status = ?",
            [numbers, "available"]
        );

        const availableNumbers = rows.map((r: any) => r.lotto_number);

        if (availableNumbers.length !== numbers.length) {
            return {
                success: false,
                message: "เลขบางตัวถูกซื้อไปแล้ว หรือหมายเลขไม่ถูกต้อง",
                totalPrice: 0,
            };
        }

        // ซื้อทั้งหมด: update status
        //TODO:::
        // await pool.query(
        //     "UPDATE lotto SET status = 'sold' WHERE lotto_number IN (?)",
        //     [numbers]
        // );

        // หักเงินผู้ใช้
        await pool.query(
            "UPDATE users SET money = money - ? WHERE uid = ?",
            [totalPrice, userId]
        );

        // บันทึก history สำหรับแต่ละเลข ใช้ user_id แทน username
        for (const lottoNumber of numbers) {
            await pool.query(
                "INSERT INTO history (lotto_number, user_id) VALUES (?, ?)",
                [lottoNumber, userId]
            );
        }

        return {
            success: true,
            message: `ซื้อสำเร็จ ${numbers.length} ใบ ยอดเงินรวม ${totalPrice} บาท`,
            totalPrice,
        };

    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการซื้อล็อตเตอรี่:", error);
        return {
            success: false,
            message: "เกิดข้อผิดพลาด",
            totalPrice: 0,
        };
    }
}

export async function hasBeenDrawn(): Promise<boolean> {
  try {
      const [rows] = await pool.query<RowDataPacket[]>(
          "SELECT id FROM lotto_results LIMIT 1"
      );
      return rows.length > 0;
  } catch (error) {
      console.error("เกิดข้อผิดพลาดในการตรวจสอบรางวัล:", error);
      return false;
  }
}
export async function createLottoResults(lottoNumber: string[]): Promise<boolean> {
  try {
      const prizeAmount: string[] = ["6000000", "200000", "80000", "4000", "2000"];

      // รางวัลที่ 1-3
      for (let i = 0; i < 3; i++) {
          await pool.query(
              "INSERT INTO lotto_results (prize_name, prize_amount, lotto_number) VALUES (?, ?, ?)", 
              [`รางวัลที่ ${i + 1}`, prizeAmount[i], lottoNumber[i]]
          );
      }

      // เลขท้าย 3 ตัว
      await pool.query(
          "INSERT INTO lotto_results (prize_name, prize_amount, lotto_number) VALUES (?, ?, ?)", 
          ["เลขท้าย 3 ตัว", prizeAmount[3], lottoNumber[3]]
      ); 

      // เลขท้าย 2 ตัว
      await pool.query(
          "INSERT INTO lotto_results (prize_name, prize_amount, lotto_number) VALUES (?, ?, ?)", 
          ["เลขท้าย 2 ตัว", prizeAmount[4], lottoNumber[4]]
      ); 
      return true;
  } catch (error) {
      console.error("เกิดข้อผิดพลาดในการตรวจสอบรางวัล:", error);
      return false;
  }
}
