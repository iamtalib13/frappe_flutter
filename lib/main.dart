import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'home_page.dart';
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
      home: const CheckSession(), // Changed from LoginPage
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheckSession extends StatefulWidget {
  const CheckSession({super.key});

  @override
  _CheckSessionState createState() => _CheckSessionState();
}

class _CheckSessionState extends State<CheckSession> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final sid = await _secureStorage.read(key: 'sid');
    final fullName = await _secureStorage.read(key: 'fullName');
    final email = await _secureStorage.read(key: 'email');

    // A small delay to avoid a jarring transition
    await Future.delayed(const Duration(seconds: 1));

    if (sid != null && fullName != null && email != null) {
      Get.offAll(() => HomePage(fullName: fullName, email: email));
    } else {
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
