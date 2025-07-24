import 'dart:developer';

import 'package:Lotto2025/pages/register.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      // title: Text("Login Page"),
      ), 
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/logo.png',fit: BoxFit.contain),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Lotto2025",
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30.0, right: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("เบอร์โทรศัพท์",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), // border circle
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 30.0, right: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("รหัสผ่าน",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), // border circle
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ],
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20.0, top: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => register(context), child: const Text("ลงทะเบียน",
                      style: TextStyle(fontSize: 25),
                    )),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(fontSize: 25),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),      
      ), 
    );
  }

  void register(BuildContext context) {
    log("register");
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 100), // fade speed
      ),
    );
  }

  void login(String phone, String pass) {
    log("login");
  }
}
