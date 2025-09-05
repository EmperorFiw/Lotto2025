import 'package:Lotto2025/model/user/user_state.dart';
import 'package:Lotto2025/pages/admin/admin_dashboard.dart';
import 'package:Lotto2025/pages/dashboard.dart';
import 'package:flutter/material.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    final user = UserState().currentUser;

    if (UserState().isAdmin) {
      return const AdminDashboardPage();
    } else {
      return const DashboardPage();
    }
  }
}
