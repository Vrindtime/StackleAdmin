import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stackle_admin/data/services/auth_service.dart';
import 'package:stackle_admin/view/auth/login_screen.dart';
import 'package:stackle_admin/view/main_dashboard.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var accessToken = "".obs;
  var refreshToken = "".obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Load tokens from storage when controller initializes
    _loadTokensFromStorage();
  }

  void _loadTokensFromStorage() {
    final storedAccessToken = box.read("access_token") ?? "";
    final storedRefreshToken = box.read("refresh_token") ?? "";

    accessToken.value = storedAccessToken;
    refreshToken.value = storedRefreshToken;

    print('AuthController: Loaded tokens from storage:');
    print(
        '  - access_token: ${storedAccessToken.isNotEmpty ? "Found (${storedAccessToken.length} chars)" : "Empty"}');
    print(
        '  - refresh_token: ${storedRefreshToken.isNotEmpty ? "Found (${storedRefreshToken.length} chars)" : "Empty"}');
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final data = await _authService.login(email, password);

      //Save tokens in memory
      accessToken.value = data["access"] ?? "";
      refreshToken.value = data["refresh"] ?? "";

      // Save tokens to local storage with timestamp
      box.write("access_token", accessToken.value);
      box.write("refresh_token", refreshToken.value);
      box.write("token_timestamp", DateTime.now().millisecondsSinceEpoch);

      print('AuthController: Saved tokens to storage:');
      print(
          '  - access_token: ${accessToken.value.isNotEmpty ? "Saved (${accessToken.value.length} chars)" : "Empty"}');
      print(
          '  - refresh_token: ${refreshToken.value.isNotEmpty ? "Saved (${refreshToken.value.length} chars)" : "Empty"}');
      print('  - token_timestamp: ${DateTime.now().millisecondsSinceEpoch}');

      // navigate to dashboard after passing msg
      Get.snackbar(
        "Success",
        "Logged in successfully",
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF1B5E20),
      );
      Get.offAll(() => const MainDashboard());
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    // Clear tokens from memory
    accessToken.value = "";
    refreshToken.value = "";

    // Clear saved tokens and timestamp from local storage
    box.remove("access_token");
    box.remove("refresh_token");
    box.remove("token_timestamp");

    // navigate to login
    Get.offAll(() => LoginScreen());
  }

  bool isTokenExpired() {
    if (accessToken.value.isEmpty) return true;

    final tokenTimestamp = box.read('token_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final tokenAge = currentTime - tokenTimestamp;
    const twentyFourHours = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    return tokenAge >= twentyFourHours;
  }

  Future<void> checkAndRefreshToken() async {
    if (accessToken.value.isEmpty) return;

    try {
      // Check if token is expired based on timestamp (24 hours)
      final tokenTimestamp = box.read('token_timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final tokenAge = currentTime - tokenTimestamp;
      const twentyFourHours = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

      if (tokenAge >= twentyFourHours) {
        // Token is expired, try to refresh
        final refreshTokenValue = refreshToken.value;
        if (refreshTokenValue.isNotEmpty) {
          final newTokens = await _authService.refreshToken(refreshTokenValue);
          if (newTokens != null && newTokens.isNotEmpty) {
            final newAccessToken = newTokens['access'] ?? '';
            final newRefreshToken = newTokens['refresh'] ?? refreshTokenValue;

            if (newAccessToken.isNotEmpty) {
              accessToken.value = newAccessToken;
              refreshToken.value = newRefreshToken;

              box.write("access_token", newAccessToken);
              box.write("refresh_token", newRefreshToken);
              box.write(
                  "token_timestamp", DateTime.now().millisecondsSinceEpoch);
            }
          }
        }
      }
    } catch (e) {
      print('Token refresh check failed: $e');
    }
  }
}
