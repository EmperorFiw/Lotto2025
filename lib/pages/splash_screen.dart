import 'dart:async';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isCheckingApi = true;
  String? errorMessage;
  String? apiEndpoint;

  @override
  void initState() {
    super.initState();
    _loadConfigAndCheckApi();
  }

  Future<void> _loadConfigAndCheckApi() async {
    setState(() {
      isCheckingApi = true;
      errorMessage = null;
    });

    try {
      final config = await Configuration.getConfig();
      log('Config loaded: $config');  // เพิ่มบรรทัดนี้ดูค่า config
      apiEndpoint = config['apiEndpoint'] ?? '';

      if (apiEndpoint == null || apiEndpoint!.isEmpty) {
        setState(() {
          errorMessage = 'Error กรุณาติดต่อผู้ดูแลระบบ';
          isCheckingApi = false;
        });
        return;
      }

      final response = await http.get(Uri.parse('$apiEndpoint/health_check')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _goToLogin();
      } else {
        setState(() {
          errorMessage = '(Error code: ${response.statusCode}) กรุณาลองใหม่อีกครั้ง';
          isCheckingApi = false;
        });
      }
    } on TimeoutException {
      setState(() {
        errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ เนื่องจากหมดเวลาการเชื่อมต่อ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง';
        isCheckingApi = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง';
        isCheckingApi = false;
      });
    }
  }


  void _retry() {
    _loadConfigAndCheckApi();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isCheckingApi
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    errorMessage ?? 'Internal Server Error',
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
      ),
    );
  }
}
