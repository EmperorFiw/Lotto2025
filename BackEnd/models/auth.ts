import bcrypt from "bcrypt";
import { pool } from "../database/db";

const SALT_ROUNDS = 10;

// หา user ตาม username
export async function findUserByUsername(username: string) {
    const [rows]: any[] = await pool.query(
        "SELECT username, password, money, role FROM users WHERE username = ?",
        [username]
    );
    if (rows.length === 0) return null;
    return rows[0];
}

// ตรวจสอบ username ซ้ำ
export async function isUsernameTaken(username: string) {
    const [rows]: any = await pool.query(
        "SELECT username FROM users WHERE username = ?",
        [username]
    );
    return rows.length > 0;
}

// สร้าง user ใหม่ (hash password ก่อนเก็บ)
export async function createUser(username: string, password: string, phone: string, money: number, role = "user") {
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

    const [result] = await pool.query(
        "INSERT INTO users (username, password, phone, money, role) VALUES (?, ?, ?, ?, ?)",
        [username, hashedPassword, phone, money, role]
    );
    return result;
}

// ตรวจสอบรหัสผ่าน
export async function verifyPassword(inputPassword: string, hashedPassword: string) {
    return bcrypt.compare(inputPassword, hashedPassword);
}
