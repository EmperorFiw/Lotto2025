import 'package:flutter/material.dart';

import 'claim_lotto.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // JSON จำลอง (เหมือนดึงจาก API)
  final List<Map<String, dynamic>> mockTickets = const [
    {
      "numbers": [1, 2, 3, 4, 5, 6],
      "set": 1,
      "status": "ตรวจผล", // "ไม่ถูกรางวัล", "ขึ้นเงิน"
    },
    {
      "numbers": [9, 9, 9, 9, 9, 9],
      "set": 2,
      "status": "ไม่ถูกรางวัล",
    },
    {
      "numbers": [5, 6, 7, 8, 9, 0],
      "set": 3,
      "status": "ขึ้นเงิน",
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
      case "ตรวจผล":
        return const Color(0xFF2196F3); // ฟ้า
      case "ไม่ถูกรางวัล":
        return Colors.grey; // เทา
      case "ขึ้นเงิน":
        return Colors.green; // เขียว
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - Card Style Design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header แถบสีแดงด้านบน
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC3545),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'LT-Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ส่วนเนื้อหาด้านล่าง
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลโปรไฟล์',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Balance + Lotto Count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เงินคงเหลือ',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '999 บาท',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'จำนวนลอตโต้ทั้งหมด',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '3 ใบ',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List ลอตเตอรี่ที่คุณมี
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ลอตโต้ที่คุณมี',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ListView ลอตเตอรี่
                    Expanded(
                      child: ListView.builder(
                        itemCount: mockTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = mockTickets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // เลขลอตเตอรี่
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCDD2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children:
                                          List.generate(ticket["numbers"].length,
                                              (i) {
                                        return Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${ticket["numbers"][i]}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // ชุดที่
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'ชุดที่',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${ticket["set"]}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // ปุ่มสถานะ
                               // ปุ่มสถานะ
                              ElevatedButton(
                                onPressed: () {
                                  if (ticket["status"] == "ขึ้นเงิน") {
                                    // เด้งไปหน้า ClaimLottoPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ClaimLottoPage(),
                                      ),
                                    );
                                  } else {
                                    // TODO: logic ตรวจผลอื่นๆ
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('สถานะ: ${ticket["status"]}')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _statusColor(ticket["status"]),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  ticket["status"],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
