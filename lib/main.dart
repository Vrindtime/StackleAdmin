import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stackle_admin/core/routing.dart';

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
      getPages: AppRoutes.getPages,
      
      // usePathUrlStrategy: true
    );
  }
}
