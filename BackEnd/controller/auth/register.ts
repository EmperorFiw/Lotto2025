import express from "express";
import { createUser, isUsernameTaken } from "../../models/auth";
import { generateToken } from "./jwt";

export const router = express.Router();

router.post("/", async (req, res) => {
    try {
        const { phone, username, password, money } = req.body;

        if (
            typeof username !== "string" || username.trim() === "" ||
            typeof password !== "string" || password.trim() === "" ||
            typeof phone !== "string" || phone.trim() === "" ||
            typeof money !== "number" || money < 0
        ) {
            return res.status(400).json({
                success: false,
                message: "กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง",
            });
        }

        if (await isUsernameTaken(username)) {
            return res.status(400).json({
                success: false,
                message: "ชื่อผู้ใช้นี้ถูกใช้ไปแล้ว",
            });
        }

        await createUser(username, password, phone, money);

        const token = generateToken({ username, money, role: "user" });

        return res.status(201).json({
            success: true,
            message: "สมัครสมาชิกสำเร็จ",
            token,
        });

    } catch (error) {
        console.error("เกิดข้อผิดพลาดในการสมัครสมาชิก:", error);
        return res.status(500).json({
            success: false,
            message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
        });
    }
});
