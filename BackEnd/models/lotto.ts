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
      const [rows]: any = await pool.query(
        "SELECT COUNT(*) as count FROM lotto_results"
      );
      return rows[0].count >= 5;
    } catch (error) {
      console.error("Error checking if lottery has been drawn:", error);
      return false;
    }
}

export async function getPrizeDraw(): Promise<number> {
    try {
        const [rows]: any = await pool.query(
            "SELECT COUNT(*) as count FROM lotto_results"
        );
        return rows[0].count; // คืนจำนวนรางวัลที่ออกไปแล้ว
    } catch (error) {
        console.error("Error :", error);
        return 0; // ถ้า error ถือว่ายังไม่มีรางวัล
    }
}
export async function createLottoResults(lottoResults: string[]): Promise<string | false> {
	try {
		const prizeAmount = ["6000000", "200000", "80000", "4000", "2000"];
		const prizeNames = ["รางวัลที่ 1", "รางวัลที่ 2", "รางวัลที่ 3", "เลขท้าย 3 ตัว", "เลขท้าย 2 ตัว"];

		// ตรวจสอบว่ามีเลขขายแล้วเพียงพอ
		if (!lottoResults || lottoResults.length < 5) {
			console.error("ไม่พบเลขล็อตเตอรี่เพียงพอสำหรับการจับรางวัล");
			return false;
		}

		// ดึงจำนวนรางวัลที่ออกแล้ว
		const [rows]: any = await pool.query("SELECT COUNT(*) as count FROM lotto_results");
		const count = rows[0].count;

		if (count >= 5) {
			console.log("จับรางวัลครบแล้ว");
			return false;
		}

		let numberToInsert: string;

		if (count <= 2) {
			// รางวัลที่ 1–3: สุ่มจาก list ที่มีอยู่
			const randomIndex = Math.floor(Math.random() * lottoResults.length);
			numberToInsert = lottoResults[randomIndex];

			// เอาเลขที่ใช้แล้วออก เพื่อไม่ให้ซ้ำ
			lottoResults.splice(randomIndex, 1);

		} else if (count === 3) {
			// เลขท้าย 3 ตัว: อิงจากรางวัลที่ 1
			const [firstRow]: any = await pool.query(
				"SELECT lotto_number FROM lotto_results WHERE prize_name = 'รางวัลที่ 1' LIMIT 1"
			);
			numberToInsert = firstRow[0].lotto_number.slice(-3);

		} else {
			// เลขท้าย 2 ตัว: สุ่มใหม่จาก list
			const randomIndex = Math.floor(Math.random() * lottoResults.length);
			numberToInsert = lottoResults[randomIndex].slice(-2);
		}

		await pool.query(
			"INSERT INTO lotto_results (prize_name, prize_amount, lotto_number) VALUES (?, ?, ?)",
			[prizeNames[count], prizeAmount[count], numberToInsert]
		);

		console.log(`ออกเลขรางวัล ${prizeNames[count]}: ${numberToInsert}`);
		return numberToInsert;

	} catch (error) {
		console.error("เกิดข้อผิดพลาดในการบันทึกรางวัล:", error);
		return false;
	}
}
