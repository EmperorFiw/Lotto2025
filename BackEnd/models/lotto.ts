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
 * ฟังก์ชันเช็คเลขถูกรางวัล
 * @param username ชื่อผู้ใช้
 * @param number เลขลอตเตอรี่
 * @param isWin true ถูกรางวัล, false ไม่ถูกรางวัล
 */
export async function WonPrize(username: string, number: string, isWin: boolean) {
    try {
        if (isWin) {
            // ถูกรางวัล: update status = 2
            await pool.query(
                "UPDATE history SET status = 2 WHERE lotto_number = ? AND user_id = (SELECT uid FROM users WHERE username = ?)",
                [number, username]
            );
        } else {
            // ไม่ถูกรางวัล: update status = 1
            await pool.query(
                "UPDATE history SET status = 1 WHERE lotto_number = ? AND user_id = (SELECT uid FROM users WHERE username = ?)",
                [number, username]
            );
        }

        // ดึงเลขทั้งหมดที่ยัง available
        const [rows] = await pool.query(
            "SELECT lotto_number FROM lotto WHERE status = ?",
            ['available']
        );

        return (rows as any[]).map(row => row.lotto_number);
    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการอัปเดต history หรือดึง lotto:", error);
        return [];
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
        await pool.query(
            "UPDATE lotto SET status = 'sold' WHERE lotto_number IN (?)",
            [numbers]
        );

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
