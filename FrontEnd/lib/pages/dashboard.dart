import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';

import 'check_prize.dart';
import 'profile.dart'; // import หน้าโปรไฟล์

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  String apiUrl = '';
  List<String> numbers = [];
  List<bool> selected = [];
  bool isLoading = true;

  // สำหรับค้นหา
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchLotto();
  }

  // ฟังก์ชันนี้ใช้สำหรับดึงข้อมูลเลขลอตเตอรี่จาก API
  Future<void> fetchLotto() async {
    try {
      // โหลด config ของ API จากไฟล์ Configuration
      final config = await Configuration.getConfig();

      // ดึง endpoint ของ API จาก config (เช่น https://api.lotto2025.com)
      apiUrl = config['apiEndpoint'] ?? '';

      // ดึง JWT token ของผู้ใช้ปัจจุบันจาก UserState
      final token = UserState().token;

      // ส่ง HTTP GET request ไปยัง API เพื่อดึงเลขลอตเตอรี่
      final response = await http.get(
        Uri.parse("$apiUrl/lotto/fetchlotto"), // URL ของ API
        headers: {
          "Authorization": "Bearer $token", // ใส่ JWT สำหรับตรวจสอบสิทธิ์
          "Content-Type": "application/json", // กำหนดว่าข้อมูลรับส่งเป็น JSON
        },
      );

      // ถ้า HTTP status code = 200 (สำเร็จ)
      if (response.statusCode == 200) {
        // แปลง JSON response เป็น Map ของ Dart
        final data = jsonDecode(response.body);

        // ตรวจสอบว่า API ส่งข้อมูลสำเร็จหรือไม่
        if (data["success"] == true) {
          // ถ้า successful → อัปเดต state ของ widget
          setState(() {
            // เก็บเลขลอตเตอรี่ทั้งหมดลงใน List<String>
            numbers = List<String>.from(data["numbers"]);

            // สร้าง List<bool สำหรับ track การเลือกของผู้ใช้ (false = ยังไม่เลือก)
            selected = List<bool>.filled(numbers.length, false);

            // ปิด loading indicator
            isLoading = false;
          });
        }
      } else {
        // ถ้า HTTP status code ไม่ใช่ 200 → log error
        log("Error fetching lotto: ${response.statusCode}");

        // ปิด loading indicator
        setState(() => isLoading = false);
      }
    } catch (e) {
      // ถ้ามี exception เกิดขึ้น เช่น network error
      log("Fetch lotto failed: $e");

      // ปิด loading indicator
      setState(() => isLoading = false);
    }
  }

  // ฟังก์ชันนี้ใช้สำหรับซื้อเลขลอตเตอรี่ที่ผู้ใช้เลือก
  Future<void> buySelectedTickets(List<String> selectedNumbers) async {
    // ดึง JWT token ของผู้ใช้
    final token = UserState().token;

    // ตรวจสอบเบื้องต้น ถ้าไม่มี API URL, ไม่มี token, หรือไม่เลือกเลข → ออกจากฟังก์ชันทันที
    if (apiUrl.isEmpty || token == null || selectedNumbers.isEmpty) return;

    try {
      // ส่ง HTTP POST request ไปยัง API /lotto/buy เพื่อทำการซื้อ
      final response = await http.post(
        Uri.parse('$apiUrl/lotto/buy'), // URL ของ API
        headers: {
          "Authorization": "Bearer $token", // ใส่ JWT สำหรับตรวจสอบสิทธิ์
          "Content-Type": "application/json", // กำหนดว่า request body เป็น JSON
        },
        // body ของ POST request เป็น JSON array ของเลขที่ผู้ใช้เลือก
        body: jsonEncode({"numbers": selectedNumbers}),
      );

      // ถ้า HTTP status code ไม่ใช่ 200 → แสดง error
      if (response.statusCode != 200) {
        log('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ซื้อไม่สำเร็จ (${response.statusCode})')),
        );
        return;
      }

      // แปลง JSON response เป็น Map
      final data = jsonDecode(response.body);

      // ตรวจสอบว่า API ตอบว่าซื้อสำเร็จหรือไม่
      if (data['success'] == true) {
        // ถ้าผู้ใช้มีข้อมูลใน UserState ให้ปรับยอดเงิน
        final user = UserState().currentUser;
        if (user != null) {
          // ดึง totalPrice จาก response → แปลงเป็น int ให้แน่นอน
          final priceRaw = data['totalPrice'] ?? 0;
          final priceNum = priceRaw is int
              ? priceRaw
              : (priceRaw is double
                    ? priceRaw.toInt()
                    : int.tryParse(priceRaw.toString()) ?? 0);

          // คำนวณยอดเงินใหม่ = เงินเดิม - ราคาซื้อ
          final newMoney = user.money - priceNum;

          // อัปเดตยอดเงินใน UserState
          UserState().updateMoney(newMoney);
        }

        // แจ้งผู้ใช้ว่าซื้อสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "ซื้อสำเร็จ")),
        );

        // ล้างการเลือกเลขทั้งหมดใน List
        setState(() {
          selected = List<bool>.filled(numbers.length, false);
        });
      } else {
        // ถ้า API ตอบว่าซื้อไม่สำเร็จ → แสดง message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "ซื้อไม่สำเร็จ")),
        );
      }
    } catch (e) {
      // ถ้าเกิด exception เช่น network error
      log('Network error: $e');

      // แจ้งผู้ใช้ว่าเกิดข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserState().currentUser;
    int wallet = user?.money.toInt() ?? 0;

    int selectedCount = selected.where((e) => e).length;
    int totalPrice = selectedCount * 80;

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

  Widget _buildHomePage(int selectedCount, int totalPrice, int wallet) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (numbers.isEmpty) {
      return const Center(child: Text("ไม่พบข้อมูลลอตเตอรี่"));
    }

    List<String> selectedNumbers = [];
    for (int i = 0; i < numbers.length; i++) {
      if (selected[i]) selectedNumbers.add(numbers[i]);
    }

    return StatefulBuilder(
      builder: (context, setInnerState) {
        final displayedNumbers = numbers
            .where((num) => num.contains(searchText))
            .toList();

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // ช่องค้นหา
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "ค้นหาเลขลอตเตอรี่...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setInnerState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "ชุดเลขลอตโต้",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayedNumbers.length,
                    itemBuilder: (context, index) {
                      final mainIndex = numbers.indexOf(
                        displayedNumbers[index],
                      );
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
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: numbers[mainIndex],
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 6,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '\n ใบละ 80 บาท',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text("ชุดที่ ${mainIndex + 1}"),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selected[mainIndex]
                                          ? Colors.blue.shade900
                                          : Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {
                                      setInnerState(() {
                                        selected[mainIndex] =
                                            !selected[mainIndex];
                                      });
                                      setState(() {});
                                    },
                                    child: Text(
                                      selected[mainIndex] ? "เอาออก" : "เลือก",
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
            if (selectedCount > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 18,
                  ),
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
                                    style: TextStyle(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    buySelectedTickets(selectedNumbers);
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
      },
    );
  }
}
