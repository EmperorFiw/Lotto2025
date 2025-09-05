import 'dart:convert';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'check_prize.dart';
import 'profile.dart';

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

  TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadConfig(); // โหลด config ก่อน
  }

  Future<void> _loadConfig() async {
    final config = await Configuration.getConfig();
    apiUrl = config['apiEndpoint'] ?? '';
    // ถ้าเปิดมาแล้วอยู่หน้า Home ให้ fetch เลขเลย
    if (_currentIndex == 0) {
      await _loadLotto();
    }
  }

  Future<void> _loadLotto() async {
    if (apiUrl.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final token = UserState().token;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiUrl/lotto/fetchlotto'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            numbers = List<String>.from(data['numbers'] ?? []);
            selected = List<bool>.filled(numbers.length, false);
          });
        } else {
          log('Failed to load lotto: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'โหลดข้อมูลไม่สำเร็จ')),
          );
        }
      } else {
        log('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})')),
        );
      }
    } catch (e) {
      log('Error loading lotto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> buySelectedTickets(List<String> selectedNumbers) async {
    final token = UserState().token;
    if (apiUrl.isEmpty || token == null || selectedNumbers.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/lotto/buy'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"numbers": selectedNumbers}),
      );

      if (response.statusCode != 200) {
        log('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ซื้อไม่สำเร็จ (${response.statusCode})')),
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final user = UserState().currentUser;
        if (user != null) {
          final priceRaw = data['totalPrice'] ?? 0;
          final priceNum = priceRaw is int
              ? priceRaw
              : (priceRaw is double
                  ? priceRaw.toInt()
                  : int.tryParse(priceRaw.toString()) ?? 0);
          final newMoney = user.money - priceNum;
          UserState().updateMoney(newMoney);
        }

        // รีโหลดเลขใหม่หลังซื้อสำเร็จ
        await _loadLotto();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "ซื้อสำเร็จ")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "ซื้อไม่สำเร็จ")),
        );
      }
    } catch (e) {
      log('Network error: $e');
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
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.red,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        onTap: (index) async {
          // ถ้าไปหน้า Home และ index เปลี่ยน ต้องโหลดเลขใหม่
          if (index == 0 && _currentIndex != 0) {
            await _loadLotto();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "ตรวจรางวัล"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }

  Widget _buildHomePage(int selectedCount, int totalPrice, int wallet) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (numbers.isEmpty) return const Center(child: Text("ไม่พบข้อมูลลอตเตอรี่"));

    List<String> selectedNumbers = [];
    for (int i = 0; i < numbers.length; i++) {
      if (selected[i]) selectedNumbers.add(numbers[i]);
    }

    return StatefulBuilder(
      builder: (context, setInnerState) {
        final displayedNumbers =
            numbers.where((num) => num.contains(searchText)).toList();

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
                      final mainIndex = numbers.indexOf(displayedNumbers[index]);
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
                                    horizontal: 16, vertical: 8),
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
                                          color: Colors.white, fontSize: 16),
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
                      vertical: 15, horizontal: 18),
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
                                        color: Colors.red),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                ElevatedButton(
                                  child: const Text(
                                    "ชำระเงิน",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
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
