import express from "express";
import { fetchLottoHistory, fetchProfile } from "../../models/user"; // สมมุติไฟล์นี้

export const router = express.Router();

router.get("/", async (req:any, res) => {
	try {
		const username = req.auth?.username;

		const user = await fetchProfile(username);
		if (!user || !username) {
			return res.status(404).json({ success: false, message: "ไม่พบผู้ใช้" });
		}
		const lottoTickets = await fetchLottoHistory(username);

		res.json({
			success: true,
			user,
			lottoTickets: lottoTickets ?? [],
		});
	} catch (error) {
		console.error("Error fetching profile:", error);
		res.status(500).json({ success: false, message: "เกิดข้อผิดพลาด" });
	}
});
