import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CheckPrize extends StatefulWidget {
  const CheckPrize({super.key});
  @override
  State<CheckPrize> createState() => _CheckPrizeState();
}

class _CheckPrizeState extends State<CheckPrize> {
  // ตัวควบคุม TextField
  final TextEditingController lotteryController = TextEditingController();
  // เก็บค่าหมายเลข 6 หลัก
  String currentNumbers = '------';

  List<Map<String, dynamic>> prizeData = [];
  String apiEndpoint = '';
  DateTime? lastUpdated;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRandomPage();
  }

  /// โหลดข้อมูลจริงจาก API (ถ้ามี)
  Future<void> _loadRandomPage() async {
    final config = await Configuration.getConfig();
    apiEndpoint = config['apiEndpoint'] ?? '';

    if (mounted) setState(() => isLoading = true);

    try {
      final token = UserState().token;
      if (token == null) {
        if (mounted) setState(() => isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่ได้เข้าสู่ระบบ: กรุณาเข้าสู่ระบบก่อน'),
              ),
            );
          }
        });
        return;
      }

      //ดึงรางวัล
      final response = await http.get(
        Uri.parse('$apiEndpoint/lotto/results'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('GET ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          if (data['success'] == true) {
            updatePrizeData(data);
            if (mounted) setState(() => lastUpdated = DateTime.now());
          } else {
            final message = (data['message'] ?? 'โหลดข้อมูลไม่สำเร็จ')
                .toString();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
            });
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('รูปแบบข้อมูลจาก API ไม่ถูกต้อง')),
              );
          });
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})'),
              ),
            );
        });
      }
    } catch (e, st) {
      log('Error loading results: $e\n$st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
          );
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// อัปเดต prizeData และรีเฟรช UI
  void updatePrizeData(Map<String, dynamic> data) {
    if (data['success'] == true) {
      setState(() {
        prizeData = List<Map<String, dynamic>>.from(
          data['lotto_results'] ?? [],
        );

        // ✅ ตั้งค่า currentNumbers จากเลขรางวัลที่ 1 (หรือ fallback ถ้าไม่มี)
        if (prizeData.isNotEmpty) {
          final firstPrize = prizeData.first;
          final numStr = (firstPrize['number'] ?? '').toString();

          currentNumbers = numStr.padLeft(6, '0');
        } else {
          currentNumbers = '000000';
        }
      });
    }
  }

  // ฟังก์ชันตรวจรางวัล
  Future<void> checkPrizeLotto() async {
    final inputNumber = lotteryController.text;

    try {
      final token = UserState().token;
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse("$apiEndpoint/lotto/check_lotto"),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"number": inputNumber}),
      );

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (!mounted) return;

      final bool isWon = data["success"] == true;
      final String message = data["message"];

      if (inputNumber.length < 6 || inputNumber.isEmpty) {
        // ถ้าไม่ครบ 6 หลัก
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            backgroundColor: const Color.fromARGB(255, 241, 185, 185),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 48,
                    color: const Color.fromARGB(255, 255, 234, 5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ตัวเลขสลากไม่ครบ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'กรุณากรอกเลขสลากให้ครบ 6 ตัวเลข',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),

                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ยืนยัน',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      if (isWon) {
        // ถ้าตรวจถูกรางวัล
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_box,
                    size: 48,
                    color: const Color.fromARGB(255, 44, 229, 8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยินดีด้วยคุณถูกรางวัล',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center), // แสดง massage
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 16, 163, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ตกลง',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        //ไม่ถูกรางวัล
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close,
                    size: 50,
                    color: const Color.fromARGB(255, 246, 0, 82),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'คุณไม่ถูกรางวัล',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center), // แสดง massage
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 16, 163, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ตกลง',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      _loadRandomPage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ฟังก์ชันล้างค่า
  void resetNumbers() {
    lotteryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลล็อตโต้
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 146, 143, 143),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ลอตโต้ประจำวันที่ 1 สิงหาคม 2568',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0,
                          ),
                        ),
                        GestureDetector(
                          onTap: resetNumbers,
                          child: Text(
                            'ล้างค่า',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'กรอกตัวเลขสลากที่ต้องการตรวจสอบ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 20),

                    // ช่องกรอกหมายเลข 6 หลัก
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(248, 246, 171, 171),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 240,
                          child: TextField(
                            controller: lotteryController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly, // ใส่ได้แต่ตัวเลข
                            ],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 8,
                            ),
                            decoration: const InputDecoration(
                              counterText: "",
                              hintText: 'กรอกเลขสลาก',
                              hintStyle: TextStyle(
                                color: Color.fromARGB(255, 241, 223, 223),
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // check Button (อยู่ตรงกลาง)
                    Center(
                      child: ElevatedButton(
                        onPressed: checkPrizeLotto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC3545),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'ตรวจรางวัล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (prizeData.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('ยังไม่มีข้อมูลรางวัลจาก API'),
                  ),
                )
              else
                ...prizeData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final Map<String, dynamic> prize = entry.value;
                  return Column(
                    children: [
                      _buildPrizeCard(
                        prize['title']?.toString() ?? '',
                        prize['amount']?.toString() ?? '',
                        prize['number']?.toString() ?? '',
                      ),
                      if (index < prizeData.length - 1)
                        const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCard(String prizeTitle, String prizeAmount, String number) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC3545),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    prizeTitle.isNotEmpty ? prizeTitle : '(ไม่มีชื่อรางวัล)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  prizeAmount.isNotEmpty ? prizeAmount : '-',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                number.isNotEmpty ? number : '-',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}