import 'dart:convert';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/user/user_state.dart';
import 'package:Lotto2025/pages/login.dart';
import 'package:Lotto2025/pages/mainApp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();

  String apiUrl = '';
  bool isLoadingConfig = true;
  bool isRegistering = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _moneyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        apiUrl = config['apiEndpoint'] ?? '';
        isLoadingConfig = false;
      });
    } catch (e) {
      setState(() {
        isLoadingConfig = false;
      });
      log('Failed to load config: $e');
    }
  }

  Future<void> register() async {
    if (isRegistering) return;

    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final money = int.tryParse(_moneyController.text.trim()) ?? 0;

    if (phone.isEmpty || username.isEmpty || password.isEmpty || money <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
      );
      return;
    }

    setState(() {
      isRegistering = true;
    });

    try {
      final uri = Uri.parse('$apiUrl/auth/register');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'username': username,
          'password': password,
          'money': money,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final token = data['token'];
        UserState().token = token;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')),
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainApp(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 100),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'สมัครสมาชิกไม่สำเร็จ')),
        );
      }
    } catch (e) {
      log('Register error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการสมัครสมาชิก')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Lotto2025",
                style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้ใช้',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.supervised_user_circle_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _moneyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'จำนวนเงินเริ่มต้น',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: goToLogin,
                  child: const Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 25)),
                ),
                FilledButton(
                  onPressed: isRegistering ? null : register,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: isRegistering
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("ลงทะเบียน", style: TextStyle(fontSize: 25)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
