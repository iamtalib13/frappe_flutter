import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart'; // New import
import 'package:frappe_flutter/models/lead_model.dart'; // New import for Isar model
import 'package:frappe_flutter/models/appointment_model.dart'; // New import for Isar model
import 'package:path_provider/path_provider.dart'; // New import for path

import 'home_page.dart';
import 'login_page.dart';

late Isar isar; // Global Isar instance

void main() async { // main needs to be async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  final dir = await getApplicationDocumentsDirectory(); // Get application documents directory
  isar = await Isar.open( // Open Isar instance
    [LeadSchema, AppointmentSchema], // List of all Isar collections (schemas)
    directory: dir.path,
    inspector: true, // Enable Isar inspector for debugging
  );

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
  CheckSessionState createState() => CheckSessionState();
}

class CheckSessionState extends State<CheckSession> {
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
    final Dio dio = Dio();

    await Future.delayed(const Duration(seconds: 1));

    if (sid != null && fullName != null && email != null) {
      try {
        final userResponse = await dio.get(
          'https://mysahayog.com/api/method/frappe.auth.get_logged_user',
          options: Options(
            headers: {'Cookie': 'sid=$sid'},
          ),
        );
        final loggedInUser = userResponse.data['message'];

        if (loggedInUser != null) {
          final isAdmin = (loggedInUser.toLowerCase() == 'administrator');
          await _secureStorage.write(key: 'isAdmin', value: isAdmin.toString());

          Get.offAll(() => HomePage(fullName: fullName, email: email, isAdmin: isAdmin));
        } else {
          Get.snackbar('Error', 'Could not retrieve logged in user.');
          Get.offAll(() => const LoginPage());
        }
      } on DioException catch (e) {
        Get.snackbar('Error', e.response?.data['message'] ?? 'Authentication failed.');
        Get.offAll(() => const LoginPage());
      }
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
