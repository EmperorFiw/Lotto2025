import 'package:Lotto2025/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(seedColor: const Color(0xFFFF1744));
    final customScheme = baseScheme.copyWith(
      primary: const Color(0xFFFF1744),
      secondary: const Color(0xFFFF80AB),
    );

    return MaterialApp(
      title: 'Lotto 2025',
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(), // ไทยฟ้อน
        colorScheme: customScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: customScheme.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: customScheme.primary,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
