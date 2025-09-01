import 'package:flutter/material.dart';
import 'package:Lotto2025/pages/dashboard.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
