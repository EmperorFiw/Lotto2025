// import 'dart:math';

import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // จำลองตัวเลข
  final numbers = ["999999", "999999", "999999", "999999", "999999"];
  // สถานะเมื่อชุดตัวเลขถูกกด
  final List<bool> selected = [false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    int selectedCount = selected.where((e) => e).length; //จำนวนถูกเลือกทั้งหมด
    int totalPrice = selectedCount * 100; //ราคารวม

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text("LOTTO 2025"),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                "ชุดเลขลอตโต้",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    numbers[index],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text("ชุดที่ ${index + 1}"),
                                    const SizedBox(width: 50),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: selected[index]
                                            ? Colors.blue.shade900
                                            : Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selected[index] = !selected[index];
                                        });
                                      },
                                      child: Text(
                                        selected[index] ? "เอาออก" : "เลือก",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "ใบละ 100 บาท",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.red,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard),
                label: "ตรวจรางวัล",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "โปรไฟล์",
              ),
            ],
          ),
        ),

        // Popup แสดงสรุปการเลือก
        if (selectedCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 85, // อยู่เหนือ BottomNavigationBar
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "เลือกแล้ว $selectedCount ใบ รวม $totalPrice บาท",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("ยืนยันการชำระเงิน"),
                          content: Text(
                            "คุณเลือก $selectedCount ใบ รวม $totalPrice บาท",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("ยกเลิก"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              child: const Text("ชำระเงิน"),
                              onPressed: () {
                                Navigator.pop(context);
                                // ทำต่อได้ เช่น ไปหน้าชำระเงินจริง
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("ชำระเงิน"),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
