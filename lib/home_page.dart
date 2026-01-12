import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF006767),
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
