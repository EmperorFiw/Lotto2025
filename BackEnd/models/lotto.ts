import { pool } from "../database/db";
const LOTTO_PRICE: number = process.env.LOTTO_PRICE ? parseInt(process.env.LOTTO_PRICE) : 80;

export async function fetchLotto(): Promise<string[]> {
    try {
        const [rows] = await pool.query(
            "SELECT lotto_number FROM lotto WHERE status = ?",
            ['available']
        );
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
 * @param isWin 
 * @returns 
 */

export async function WonPrize(
  username: string,
  number: string,
  isWin: boolean
): Promise<string> {
  try {
    const [rows]: any = await pool.query(
      "SELECT h.hid, lr.prize_name, lr.prize_amount FROM history h \
        RIGHT JOIN lotto_results lr ON lr.lotto_number = h.lotto_number AND h.user_id = (SELECT uid FROM users WHERE username = ?) \
        WHERE lr.lotto_number = ?",
      [username, number]
    );

    if (isWin) {
      if (rows.length > 0 && rows[0].hid) {
        // เคยซื้อ อัปเดต status = 2 
        //TODO:::::::: testing
        // await pool.query(
        //   "UPDATE history SET status = 2 WHERE lotto_number = ? AND user_id = (SELECT uid FROM users WHERE username = ?)",
        //   [number, username]
        // );
        return `ยินดีด้วย! เลข ${number} ถูกรางวัล ${rows[0].prize_name} เงินรางวัล ${rows[0].prize_amount} บาท`;
      } else if (rows.length > 0) {
        // ไม่เคยซื้อ
        return `ยินดีด้วย! เลข ${number} ถูกรางวัล ${rows[0].prize_name} เงินรางวัล ${rows[0].prize_amount} บาท\nสามารถขึ้นเงินได้ที่หน้าโปรไฟล์`;
      } else {
        return `ยินดีด้วย! เลข ${number} ไม่ถูกรางวัล`;
      }
    } else {
      if (rows.length > 0 && rows[0].hid) {
        await pool.query(
          "UPDATE history SET status = 2 WHERE lotto_number = ? AND user_id = (SELECT uid FROM users WHERE username = ?)",
          [number, username]
        );
      }
      return `เสียใจด้วย เลข ${number} ไม่ถูกรางวัล`;
    }
  } catch (error) {
    console.error("เกิดข้อผิดพลาดในการอัปเดต history:", error);
    return "Internal Server Error!";
  }
}
        
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
