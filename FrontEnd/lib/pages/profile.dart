import 'dart:convert';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'claim_lotto.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int money = 0;
  List<Map<String, dynamic>> tickets = [];
  bool isLoading = true;
  String apiEndpoint = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final config = await Configuration.getConfig();
    apiEndpoint = config['apiEndpoint'] ?? '';

    setState(() => isLoading = true);

    try {
      final token = UserState().token;
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$apiEndpoint/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            money = int.tryParse(data['user']['money'].toString()) ?? 0;
            tickets = (data['lottoTickets'] as List<dynamic>? ?? [])
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        } else {
          log('Failed to load profile: ${data['message']}');
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
      log('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0: // ตรวจผล
        return const Color(0xFF2196F3);
      case 1: // ไม่ถูกรางวัล
        return Colors.grey;
      case 2: // ขึ้นเงิน
        return Colors.green;
      default:
        return Colors.black54;
    }
  }

  String _statusText(int status) {
    switch (status) {
      case 0:
        return "ตรวจผล";
      case 1:
        return "ไม่ถูกรางวัล";
      case 2:
        return "ขึ้นเงิน";
      default:
        return "ไม่ทราบสถานะ";
    }
  }

  /// ฟังก์ชันนี้แปลง string lotto_number → List<String>
  List<String> _parseLottoNumber(String? lottoNumber) {
    if (lottoNumber == null || lottoNumber.isEmpty) return [];
    return lottoNumber.split('');
  }

  Future<void> _checkLotto(String number) async {
    log("num req");
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
        body: jsonEncode({"number": number}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("ผลการตรวจหวย"),
              content: Text(data["message"] ?? "ถูกรางวัล!"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ตกลง"),
                ),
              ],
            ),
          );

          setState(() {
            _loadProfile(); // ✅ โหลดข้อมูลโปรไฟล์ใหม่หลังตรวจหวย
          });
        } else {
          if (!mounted) return;

          // แสดง SnackBar 1 วินาที
          final snackBar = SnackBar(
            content: Text(data["message"] ?? "ไม่ถูกรางวัล"),
            duration: const Duration(milliseconds: 500), // ⬅️ 1 วินาที
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          // รีเฟรช profile หลัง SnackBar 1 วินาที
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _loadProfile();
            }
          });

        }

      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'เงินคงเหลือ',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$money บาท',
                                    style: const TextStyle(
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
                                  const Text(
                                    'จำนวนลอตโต้ทั้งหมด',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tickets.length} ใบ',
                                    style: const TextStyle(
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

            // List ลอตเตอรี่
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
                    Expanded(
                      child: ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          final numbers =
                              _parseLottoNumber(ticket["lotto_number"]);
                          final status = ticket["status"] is int
                              ? ticket["status"] as int
                              : int.tryParse(ticket["status"].toString()) ?? 0;

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
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCDD2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: numbers.map((n) {
                                        return Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          child: Text(
                                            n,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    if (status == 2) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ClaimLottoPage(),
                                        ),
                                      );
                                    } else {
                                     _checkLotto(ticket["lotto_number"].toString()); 
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _statusColor(status),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _statusText(status),
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
