import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Frappe Flutter',
      theme: ThemeData(
        primaryColor: const Color(0xFF006767),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006767)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
