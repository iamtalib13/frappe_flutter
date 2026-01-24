import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_page.dart'; // Assuming LoginPage is the entry point after error

class ErrorPage extends StatelessWidget {
  final String errorMessage;

  const ErrorPage({super.key, this.errorMessage = 'An unexpected error occurred. Please contact administrator.'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Get.offAll(() => const LoginPage()); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006767),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}