import express from "express";
import { findUserByUsername, verifyPassword } from "../../models/auth";
import { generateToken } from "./jwt";

export const router = express.Router();

router.post("/", async (req, res) => {
    console.log("login request");

    try {
        const { username, password } = req.body;

        if (typeof username !== "string" || username.trim() === "" ||
            typeof password !== "string" || password.trim() === "") {
            return res.status(400).json({
                success: false,
                message: "กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ครบถ้วน",
            });
        }

        const user = await findUserByUsername(username);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
            });
        }

        // ตรวจสอบรหัสผ่านด้วย bcrypt
        const validPassword = await verifyPassword(password, user.password);
        if (!validPassword) {
            return res.status(401).json({
                success: false,
                message: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
            });
        }
        const money = Number(user.money); 
        const token = generateToken({ username: user.username, money: money, role: user.role });

        return res.status(200).json({
            success: true,
            message: "ล็อกอินสำเร็จ",
            token,
        });

    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการล็อกอิน:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
