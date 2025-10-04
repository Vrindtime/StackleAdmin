import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stackle_admin/controllers/auth_gate.dart';
import 'package:stackle_admin/view/auth/login_screen.dart';
import 'package:stackle_admin/view/auth/forgot_password_screen.dart';
import 'package:stackle_admin/view/main_dashboard.dart';

void main() async {
  await GetStorage.init();
  // Clear any existing GetX instances to prevent conflicts during hot reload
  Get.reset();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stackle Admin',
      home: const AuthGate(),
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const MainDashboard(),
        ),
      ],
    );
  }
}
