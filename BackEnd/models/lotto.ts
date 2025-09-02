import { pool } from "../Database/db";

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

export async function purchaseLotto(username: string, numbers: string[]): Promise<string[]> {
    const purchased: string[] = [];

    try {
        for (const number of numbers) {
            const [rows]: any = await pool.query(
                "SELECT * FROM lotto WHERE lotto_number = ? AND status = ?",
                [number, "available"]
            );

            if (rows.length === 0) {
                continue;
            }
            // await pool.query(
            //     "UPDATE lotto SET status = ? WHERE lotto_number = ?",
            //     ["sold", number]
            // );

            purchased.push(number);
        }

        return purchased;
    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการซื้อล็อตเตอรี่:", error);
        return purchased; // คืนเลขที่ซื้อสำเร็จไปก่อน
    }
}
