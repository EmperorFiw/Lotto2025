import 'package:flutter/material.dart';
import 'package:Lotto2025/model/user/user_state.dart';
// import 'package:Lotto2025/model/user/user_model.dart';
import 'check_prize.dart';
import 'profile.dart'; // import หน้าโปรไฟล์

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LOTTO 2025',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // จำลองตัวเลขลอตโต้
  final numbers = ["999999", "888888", "777777", "666666", "555555"];
  final List<bool> selected = [false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    // จำนวนใบที่เลือกและราคารวม
    int selectedCount = selected.where((e) => e).length;
    int totalPrice = selectedCount * 100;

    final user = UserState().currentUser;
    int wallet = user?.money.toInt() ?? 0; // เมื่อค่าเป็น null = 0

    // รวมหน้าทั้งหมด
    final List<Widget> _pages = [
      _buildHomePage(selectedCount, totalPrice, wallet),
      CheckPrize(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("LOTTO 2025"),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: Stack(children: [_pages[_currentIndex]]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.red,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "ตรวจรางวัล",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }

  // หน้าแรก: เลือกเลขลอตโต้
  Widget _buildHomePage(int selectedCount, int totalPrice, int wallet) {
    return Stack(
      children: [
        Column(
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
                      child: Row(
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
                              const SizedBox(width: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selected[index]
                                      ? Colors.blue.shade900
                                      : Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Popup แสดงสรุปการเลือก
        if (selectedCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: const [
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
                    "เลือกแล้ว $selectedCount ใบ รวม $totalPrice บาท\n"
                    "ยอดเงินคงเหลือ $wallet บาท",
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
                            "คุณเลือก $selectedCount ใบ รวม $totalPrice บาท\n"
                            "ยอดเงินคงเหลือ $wallet บาท",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              child: const Text(
                                "ยกเลิก",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              child: const Text(
                                "ชำระเงิน",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                // ไปหน้าชำระเงินต่อได้ที่นี่
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
