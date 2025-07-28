import 'dart:convert';
import 'dart:developer';

import 'package:Lotto2025/config/config.dart';
import 'package:Lotto2025/model/response/customer_login_response.dart';
import 'package:Lotto2025/pages/mainApp.dart';
import 'package:Lotto2025/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String apiUrl = '';
  bool isLoadingConfig = true;
  bool isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            const Text(
              "ชื่อผู้ใช้",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้ใช้',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.supervised_user_circle_rounded),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "รหัสผ่าน",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => register(context),
                  child: const Text("ลงทะเบียน", style: TextStyle(fontSize: 25)),
                ),
                FilledButton(
                  onPressed: apiUrl.isEmpty || isLoggingIn
                      ? null
                      : () {
                          final username = _usernameController.text.trim();
                          final pass = _passwordController.text.trim();
                          login(username, pass);
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: isLoggingIn
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 25)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        apiUrl = config['apiEndpoint'] ?? '';
        isLoadingConfig = false;
      });
      log('API URL loaded: $apiUrl');
    } catch (e) {
      setState(() {
        isLoadingConfig = false;
      });
      log('Failed to load config: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('ไม่สามารถโหลดการตั้งค่า API ได้'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<CustomerLoginPostResponse?> loginRequest({
    required String apiUrl,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$apiUrl/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final body = response.body;
      log('[log] Response body: $body');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(body);
        final token = jsonResponse['token'];
        if (token != null) {
          handleLogin(token);
        }
        return CustomerLoginPostResponse.fromJson(jsonResponse);
      } else {
        final jsonError = jsonDecode(body);
        final message = jsonError['message'] ?? 'เข้าสู่ระบบล้มเหลว';
        throw Exception(message);
      }
    } catch (e) {
      log('ข้อผิดพลาดเครือข่าย: $e');
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    if (isLoggingIn) return;

    setState(() {
      isLoggingIn = true;
    });

    try {
      final response = await loginRequest(
        apiUrl: apiUrl,
        username: username,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
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
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('เข้าสู่ระบบล้มเหลว'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  void handleLogin(String token) {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      log("🟢 Token Decoded: $decodedToken");

      String username = decodedToken['username'] ?? 'ไม่ทราบชื่อ';
      double money = (decodedToken['money'] as num?)?.toDouble() ?? 0.0;
      String role = decodedToken['role'] ?? 'ไม่ทราบ';

      log("👤 Username: $username");
      log("💰 Money: $money");
      log("🛡️ Role: $role");
    } catch (e) {
      log("❌ ไม่สามารถ decode token ได้: $e");
    }
  }

  void register(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }
}
