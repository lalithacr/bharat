import 'package:flutter/material.dart';
import 'theme/apptheme.dart';
import 'screens/loginscreen.dart';

void main() {
  runApp(const BharatApp());
}

class BharatApp extends StatelessWidget {
  const BharatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bharat Problem Solver AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,   // ✅ was lightTheme — fixed
      home: const LoginScreen(),
    );
  }
}