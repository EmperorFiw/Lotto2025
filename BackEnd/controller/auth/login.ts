import express from "express";
import { generateToken } from "./jwt";
export const router = express.Router();

router.post("/", async (req, res) => {
	console.log("login request");

	try {
		const { username, password } = req.body;

		if (!username || !password) {
			return res.status(400).json({
				success: false,
				message: "กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ครบถ้วน",
			});
		}

		if (username === "admin" && password === "1234") {
			const token = generateToken({ username, money: 100000.0, role: "admin" });

			return res.status(200).json({
				success: true,
				message: "ล็อกอินสำเร็จ",
				token: token,
			});
		} else if (username === "user" && password === "1234") {
			const token = generateToken({ username, money: 100000.0, role: "user" });

			return res.status(200).json({
				success: true,
				message: "ล็อกอินสำเร็จ",
				token: token,
			});
		} else {
			return res.status(401).json({
				success: false,
				message: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
			});
		}
	} catch (error) {
		console.error("เกิดข้อผิดพลาดในการล็อกอิน:", error);
		return res.status(500).json({
			success: false,
			message: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง",
		});
	}
});
