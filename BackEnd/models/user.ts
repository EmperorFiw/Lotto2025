import { pool } from "../database/db";

export async function fetchProfile(username: string) {
    const [rows]: any[] = await pool.query(
        "SELECT username, money, role FROM users WHERE username = ?",
        [username]
    );
    if (rows.length === 0) return null;
    return rows[0];
}

export async function fetchLottoHistory(username: string) {
    const [rows]: any[] = await pool.query(
        `SELECT h.hid, h.lotto_number, h.status, u.uid AS user_id, u.money, u.role
         FROM history h
         JOIN users u ON h.user_id = u.uid
         WHERE u.username = ?`,
        [username]
    );
    if (rows.length === 0) return [];
    return rows;
}
