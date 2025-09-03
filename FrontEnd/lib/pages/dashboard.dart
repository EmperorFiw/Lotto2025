import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';

import 'check_prize.dart';
import 'profile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // เก็บ index ของหน้าใน BottomNavigationBar (0 = หน้าแรก)
  int _currentIndex = 0;

  // เก็บ URL ของ API ที่ใช้ดึงข้อมูลและซื้อหวย
  String apiUrl = '';
  // เก็บชุดตัวเลขลอตเตอรี่ทั้งหมดที่ดึงมาจาก API
  List<String> numbers = [];
  // เก็บสถานะการเลือกของแต่ละเลข (true = ถูกเลือก, false = ไม่เลือก)
  List<bool> selected = [];

  // ใช้บอกว่าโหลดข้อมูลจาก API อยู่หรือไม่ (true = กำลังโหลด)
  bool isLoading = true;

  // สำหรับควบคุม TextField ช่องค้นหา
  TextEditingController searchController = TextEditingController();
  String searchText = ''; // เก็บข้อความที่พิมพ์ค้นหา

  @override
  void initState() {
    // เรียก initState ของ parent class เพื่อให้ Flutter เตรียม widget
    super.initState();
    fetchLotto(); // ดึงข้อมูลลอตเตอรี่จาก API ทันทีเมื่อเปิดหน้าจอ
  }

  Future<void> fetchLotto() async {
    // ฟังก์ชันดึงข้อมูลลอตเตอรี่จาก API
    try {
      // โหลดไฟล์ config (เพื่อดู endpoint ของ API)
      final config = await Configuration.getConfig();

      // อ่านค่า apiEndpoint ถ้าไม่มีให้เป็น ''
      apiUrl = config['apiEndpoint'] ?? '';

      // อ่าน token ของ user ปัจจุบันจาก UserState
      final token = UserState().token;

      final response = await http.get(
        // เรียก API แบบ GET เพื่อนำข้อมูลลอตเตอรี่
        Uri.parse("$apiUrl/lotto/fetchlotto"), // URL สำหรับเรียก API

        headers: {
          // JWT Token สำหรับยืนยันตัวตน
          "Authorization": "Bearer $token",
          // บอกว่าเราส่งและรับข้อมูลเป็น JSON
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // ถ้า API ตอบกลับด้วย status 200 (สำเร็จ)
        final data = jsonDecode(
          response.body,
        ); // แปลง JSON response เป็น Map ของ Dart
        if (data["success"] == true) {
          // ถ้า success = true แสดงว่า API ส่งข้อมูลสำเร็จ
          setState(() {
            // อัปเดต UI
            numbers = List<String>.from(
              data["numbers"],
            ); // เก็บชุดตัวเลขลอตเตอรี่ทั้งหมด
            selected = List<bool>.filled(
              numbers.length,
              false,
            ); // ตั้งค่าเลือก = false ทุกใบ
            isLoading = false; // ปิดสถานะการโหลด
          });
        }
      } else {
        log(
          "Error fetching lotto: ${response.statusCode}",
        ); // ถ้า status code != 200 ให้ log error
        setState(() => isLoading = false); // ปิดสถานะการโหลดแม้จะ error
      }
    } catch (e) {
      // ถ้าเกิด error เช่น network ล่ม
      log("Fetch lotto failed: $e"); // log ข้อผิดพลาด
      setState(() => isLoading = false); // ปิดสถานะการโหลด
    }
  }

  Future<void> buySelectedTickets(List<String> selectedNumbers) async {
    // ฟังก์ชันซื้อเลขที่เลือกไว้
    final token = UserState().token; // ดึง token ของ user

    // ถ้า API URL ว่าง, token ไม่มี หรือไม่เลือกเลขอะไรเลย ให้หยุดฟังก์ชัน
    if (apiUrl.isEmpty || token == null || selectedNumbers.isEmpty) return;

    try {
      final response = await http.post(
        // เรียก API แบบ POST เพื่อทำการซื้อ
        Uri.parse('$apiUrl/lotto/buy'), // URL สำหรับซื้อ
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        // ส่งตัวเลขที่เลือกไปเป็น JSON
        body: jsonEncode({"numbers": selectedNumbers}),
      );

      if (response.statusCode != 200) {
        // ถ้า API ตอบกลับไม่ใช่ 200 แสดงว่ามี error
        log('HTTP error: ${response.statusCode}');
        // แจ้งเตือน error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ซื้อไม่สำเร็จ (${response.statusCode})')),
        );
        return; // ออกจากฟังก์ชัน
      }

      final data = jsonDecode(response.body); // แปลง JSON เป็น Map

      if (data['success'] == true) {
        // ถ้าซื้อสำเร็จ
        final user = UserState().currentUser; // อ่านข้อมูล user ปัจจุบัน
        if (user != null) {
          // อ่านราคาที่ซื้อจาก API
          final priceRaw = data['totalPrice'] ?? 0;
          // ถ้าราคาเป็น int = priceNum เลย
          final priceNum = priceRaw is int
              ? priceRaw
              // ถ้าเป็น double ให้แปลงเป็น int
              : (priceRaw is double
                    ? priceRaw.toInt()
                    // ถ้าเป็น string ให้แปลงเป็น int หรือ = 0
                    : int.tryParse(priceRaw.toString()) ?? 0);

          final newMoney = user.money - priceNum; // หักเงินจากยอดเงินปัจจุบัน
          UserState().updateMoney(newMoney); // อัปเดตเงินใหม่ใน UserState
        }

        setState(() {
          numbers.removeWhere((num) => selectedNumbers.contains(num));
          selected = List<bool>.filled(numbers.length, false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "ซื้อสำเร็จ"),
          ), // แจ้งเตือนสำเร็จ
        );
      } else {
        // ถ้าซื้อไม่สำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "ซื้อไม่สำเร็จ"),
          ), // แจ้งเตือน error
        );
      }
    } catch (e) {
      // ถ้า network error
      log('Network error: $e'); // log error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
        ), // แจ้งเตือน error
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
