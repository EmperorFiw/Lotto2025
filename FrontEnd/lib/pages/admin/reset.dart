import 'dart:convert';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPage extends StatefulWidget {
  const ResetPage({Key? key}) : super(key: key);

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  bool isLoading = false;
  DateTime? lastUpdated;

  Future<void> callAPI(String type) async {
    String apiEndpoint = '';
    final config = await Configuration.getConfig();
    apiEndpoint = config['apiEndpoint'] ?? '';

    setState(() => isLoading = true);

    try {
      final token = UserState().token;
      if (token == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้เข้าสู่ระบบ: กรุณาเข้าสู่ระบบก่อน')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$apiEndpoint/lotto/reset'), // 🔥 ใช้ endpoint กลาง
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"type": type}), // 👈 ส่ง type ไปใน body
      );

      log('POST $type => ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        if (raw is Map && raw['success'] == true) {
          setState(() => lastUpdated = DateTime.now());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(raw['message'] ?? 'ดำเนินการสำเร็จ')),
          );
        } else {
          final msg = (raw['message'] ?? 'โหลดข้อมูลไม่สำเร็จ').toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})')),
        );
      }
    } catch (e, st) {
      log('Error calling $type: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  void resetSystem(BuildContext context) {
    callAPI("reset");
  }

  void simulateSystem(BuildContext context) {
    callAPI("simulate");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showResetDialog(context),
                child: _buildActionButton(
                  Icons.delete,
                  'รีเซ็ตระบบ',
                  Colors.grey[400]!,
                ),
              ),
              const SizedBox(width: 50),
              GestureDetector(
                onTap: () => _showSimulationDialog(context),
                child: _buildActionButton(
                  Icons.refresh,
                  'เริ่มจำลองใหม่',
                  Colors.grey[400]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color bgColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "คำเตือน",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "คุณแน่ใจหรือไม่ว่าต้องการรีเซ็ตระบบ?",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                resetSystem(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("รีเซ็ต", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSimulationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "คำเตือน",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "คุณแน่ใจหรือไม่ว่าต้องจำลองระบบอีกครั้ง?",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                simulateSystem(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("ยืนยัน", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
