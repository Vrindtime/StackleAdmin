import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stackle_admin/data/services/auth_service.dart';
import 'package:stackle_admin/data/services/user_service.dart';
import 'package:stackle_admin/data/models/user.dart';



class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  var isLoading = false.obs;
  var accessToken = "".obs;
  var refreshToken = "".obs;
  var currentUser = Rxn<User>(); // Global current user

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

      // Fetch current user data after successful login
      await fetchCurrentUser();

      // Show success message and navigate to dashboard
      Get.snackbar(
        "Success",
        "Logged in successfully",
        backgroundColor: const Color(0xFFFFD700),
        colorText: const Color(0xFF1B5E20),
      );
      
      // Navigate to dashboard after successful login
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch current user data using JWT token
  Future<void> fetchCurrentUser() async {
    try {
      if (accessToken.value.isEmpty) return;
      
      await checkAndRefreshToken();
      final token = accessToken.value;
      
      if (token.isNotEmpty) {
        final userData = await _userService.getCurrentUser(token: token);
        currentUser.value = userData;
        print('AuthController: Fetched current user: ${userData.name} (${userData.email})');
      }
    } catch (e) {
      print('AuthController: fetchCurrentUser error: $e');
      // Don't show error snackbar here as it might be called frequently
    }
  }

  /// Update current user data globally
  void updateCurrentUser(User user) {
    currentUser.value = user;
  }

  Future<void> logout() async {
    // Clear tokens from memory
    accessToken.value = "";
    refreshToken.value = "";
    currentUser.value = null; // Clear current user

    // Clear saved tokens and timestamp from local storage
    box.remove("access_token");
    box.remove("refresh_token");
    box.remove("token_timestamp");

    // Logout complete (navigation will be handled by calling code)
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
