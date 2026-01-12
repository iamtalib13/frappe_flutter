import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'login_page.dart';
import 'reset_password_page.dart';
import 'crm_page.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildCard('Reset Password', Icons.lock_reset),
            const SizedBox(width: 8.0),
            _buildCard('CRM', Icons.business),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () {
          if (title == 'Reset Password') {
            Get.to(() => const ResetPasswordPage());
          } else if (title == 'CRM') {
            Get.to(() => const CrmPage());
          }
        },
        child: SizedBox(
          width: 150,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40.0),
              const SizedBox(height: 8.0),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
