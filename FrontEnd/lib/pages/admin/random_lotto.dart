import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RandomLottoPage extends StatefulWidget {
  @override
  _RandomLottoPageState createState() => _RandomLottoPageState();
}

class _RandomLottoPageState extends State<RandomLottoPage> {
  String currentNumbers = 'xxxxxx';
  final Random _random = Random();
  bool isLoading = false;

  List<Map<String, dynamic>> prizeData = [];
  String apiEndpoint = '';
  DateTime? lastUpdated;

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
              const SnackBar(content: Text('ไม่ได้เข้าสู่ระบบ: กรุณาเข้าสู่ระบบก่อน')),
            );
          }
        });
        return;
      }

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
            final msg = (data['message'] ?? 'โหลดข้อมูลไม่สำเร็จ').toString();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            });
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รูปแบบข้อมูลจาก API ไม่ถูกต้อง')));
          });
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})')));
        });
      }
    } catch (e, st) {
      log('Error loading results: $e\n$st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')));
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// อัปเดต prizeData และรีเฟรช UI
  void updatePrizeData(Map<String, dynamic> data) {
	if (data['success'] == true) {
		setState(() {
			prizeData = (data['lotto_results'] as List<dynamic>? ?? [])
				.map((e) => Map<String, dynamic>.from(e as Map))
				.toList();

			// ✅ ตั้ง currentNumbers จากรางวัล "ตัวสุดท้าย" (fallback ถ้าไม่มี)
			if (prizeData.isNotEmpty) {
				final last = prizeData.last;
				final numStr = (last['number'] ?? '').toString();
				if (numStr.length >= 6) {
					currentNumbers = numStr.substring(0, 6);
				} else {
					currentNumbers = numStr.padLeft(6, '0');
				}
			} else {
				currentNumbers = '000000';
			}
		});
	}
}


  void _showSnackBarSafely(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  // =================== ฟังก์ชันเรียก API สุ่มเลข ===================
  Future<void> generateRandomNumbers(String type) async {
    if (apiEndpoint.isEmpty) {
      _showSnackBarSafely('ยังไม่ได้กำหนด API endpoint');
      return;
    }

    if (mounted) setState(() => isLoading = true);

    try {
      final token = UserState().token;
      if (token == null) {
        _showSnackBarSafely('ไม่ได้เข้าสู่ระบบ: กรุณาเข้าสู่ระบบก่อน');
        return;
      }

      final uri = Uri.parse('$apiEndpoint/lotto/prize_draw');
      final payload = {'prize_draw_type': type};
      final body = jsonEncode(payload);

      log('POST $uri payload=$body');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      log('POST ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 400) {
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map) {
            final data = Map<String, dynamic>.from(raw);
            final msg = (data['message'] ?? 'เกิดข้อผิดพลาด').toString();
            _showSnackBarSafely(msg);

            // อ่าน numbers ให้เป็น string ตัวแรก
            if (data['numbers'] != null && data['numbers'] is List && data['numbers'].isNotEmpty) {
              final firstNumber = data['numbers'][0].toString();
              setState(() {
                currentNumbers = firstNumber.padLeft(6, '0');
              });
            }

            //  refresh เพื่อ sync กับ server
            await _handleRefresh();

            if (data['success'] != true) {
              log('prize_draw returned failure: $msg');
            }
          } else {
            _showSnackBarSafely('รูปแบบ response จาก server ไม่ถูกต้อง');
          }
        } catch (_) {
          _showSnackBarSafely('ไม่สามารถอ่านข้อความจาก server');
        }
      } else {
        _showSnackBarSafely('เกิดข้อผิดพลาด HTTP ${response.statusCode}');
        log('HTTP error on prize_draw: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e, st) {
      log('Error on prize_draw: $e\n$st');
      _showSnackBarSafely('เกิดข้อผิดพลาดในการเชื่อมต่อขณะสุ่มรางวัล');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================================================================

  /// Refresh handler for pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadRandomPage();
  }

  @override
  Widget build(BuildContext context) {
    // ถ้าโหลดข้อมูลอยู่ ให้แสดง loading หน้าเดียว
    if (isLoading && prizeData.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayNumbers = (currentNumbers.isNotEmpty ? currentNumbers : '000000').padLeft(6, '0');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // บล็อกแสดงเลข
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ลอตโต้ประจำวันที่ 1 ตุลาคม 2568',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'กดปุ่มเพื่อสุ่มตัวเลขการออกรางวัล',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (lastUpdated != null)
                    Text(
                      'อัปเดตล่าสุด: ${lastUpdated!.toLocal().toString().split('.').first}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB3BA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: displayNumbers.split('').map((number) {
                        return Container(
                          width: 35,
                          height: 35,
                          child: Center(
                            child: Text(
                              number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ปุ่มสุ่มเลข
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => generateRandomNumbers("sold"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC3545),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                          child: const Text(
                            'สุ่มออกรางวัลจากที่ขาย',
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => generateRandomNumbers("all"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC3545),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                          child: const Text(
                            'สุ่มออกรางวัลจากทั้งหมด',
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // แสดงรางวัล
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
                      )
                    ]),
                child: const Center(child: Text('ยังไม่มีข้อมูลรางวัลจาก API')),
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
                    if (index < prizeData.length - 1) const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            const SizedBox(height: 40),
          ],
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(prizeAmount.isNotEmpty ? prizeAmount : '-', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                number.isNotEmpty ? number : '-',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}