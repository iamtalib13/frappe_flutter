import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _empIdController = TextEditingController();
  final _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  String? _fullName;
  String? _email;
  bool _isLoading = false;
  bool _userFetched = false;

  Future<void> _getUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      final response = await _dio.get(
        'https://mysahayog.com/api/method/sahayog_ticket.sahayog_ticket.doctype.sahayog_ticket.sahayog_ticket.get_user_details',
        queryParameters: {'username': _empIdController.text},
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200 && response.data['message'] != null) {
        setState(() {
          _fullName = response.data['message']['full_name'];
          _email = response.data['message']['email'];
          _userFetched = true;
        });
      } else {
        Get.snackbar('Error', 'User not found');
      }
    } on DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'An error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      await _dio.post(
        'https://mysahayog.com/api/method/sahayog_ticket.sahayog_ticket.doctype.sahayog_ticket.sahayog_ticket.reset_user_password',
        data: {
          'email': _email,
          'new_password': _empIdController.text,
        },
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      Get.snackbar('Success', 'Password reset successfully');
    } on DioException catch (e) {
      Get.snackbar('Error', e.response?.data['message'] ?? 'An error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: const Color(0xFF006767),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _empIdController,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _userFetched ? _resetPassword : _getUserDetails,
                child: Text(_userFetched ? 'Reset' : 'Check'),
              ),
            const SizedBox(height: 16.0),
            if (_fullName != null && _email != null)
              Column(
                children: [
                  Text('Full Name: $_fullName'),
                  Text('USER ID: $_email'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
