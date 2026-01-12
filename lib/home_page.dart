import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String fullName;
  final String email;

  const HomePage({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _logout() async {
    await _secureStorage.delete(key: 'sid');
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.fullName),
            Text(
              widget.email,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006767),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'You are logged in',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
