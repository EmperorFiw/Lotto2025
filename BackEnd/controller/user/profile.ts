import express from "express";

export const router = express.Router();

router.get("/", (req, res) => {
    //mock data
    console.log("fetching profile");
    res.json({
        success: true,
        user: {
            username: "user",
            phone: "0812345678",
            role: "user",
            money: 1000000
        },
        lottoTickets: [
            { numbers: ["123456"], set: 1, status: "ตรวจผล" },
            { numbers: ["123458"], set: 2, status: "ไม่ถูกรางวัล" },
            { numbers: ["999999"], set: 3, status: "ขึ้นเงิน" },
        ]
    });
});
