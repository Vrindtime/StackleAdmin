import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stackle_admin/core/routing.dart';
import 'package:stackle_admin/widgets/root_notification_wrapper.dart';
import 'package:stackle_admin/controllers/notification_controller.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

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
    // Ensure the AuthController is available first since other controllers
    // (like NotificationController) use Get.find<AuthController>() in onInit.
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    // Ensure the NotificationController is available. If you prefer lazy
    // initialization, move this to your binding or another startup location.
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }

      // Use GetMaterialApp.builder to wrap the app's child with the
      // RootNotificationWrapper. That ensures Directionality/Material is
      // provided by GetMaterialApp before the wrapper builds (fixes the
      // Stack Directionality error).
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stackle Admin',
        getPages: AppRoutes.getPages,
        builder: (context, child) => RootNotificationWrapper(
          child: child ?? const SizedBox.shrink(),
        ),
      );
  }
}
