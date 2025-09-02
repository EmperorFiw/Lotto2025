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

export async function purchaseLotto(
    username: string,
    numbers: string[]
): Promise<{
    success: boolean;
    message: string;
    totalPrice: number;
}> {
    try {
        // ดึงเงินผู้ใช้
        const [userRows]: any = await pool.query(
            "SELECT money FROM users WHERE username = ?",
            [username]
        );

        if (userRows.length === 0) {
            return {
                success: false,
                message: "ไม่พบผู้ใช้",
                totalPrice: 0,
            };
        }

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

        // ซื้อทั้งหมด: update status และ owner
        await pool.query(
            "UPDATE lotto SET status = 'sold' WHERE lotto_number IN (?)",
            [numbers]
        );

        // หักเงิน
        await pool.query(
            "UPDATE users SET money = money - ? WHERE username = ?",
            [totalPrice, username]
        );

        // บันทึก history สำหรับแต่ละเลข
        for (const lottoNumber of numbers) {
            await pool.query(
                "INSERT INTO history (lotto_number, username) VALUES (?, ?)",
                [lottoNumber, username]
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
