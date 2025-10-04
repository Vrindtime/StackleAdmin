import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackle_admin/data/models/block_status.dart';
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/data/services/user_service.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class UserController extends GetxController {
  final UserService _service = UserService();

  // Observable user data
  var user = Rxn<User>();
  var currentUser = Rxn<User>(); // For current logged in user
  var isLoading = false.obs;
  var isLoadingCurrentUser = false.obs;
  var isLoadingBlockStatus = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var blockStatusError = ''.obs;
  var userBlockStatus = Rxn<BlockedUserStatus>();

  /// Fetch user details by user ID
  Future<void> fetchUserById(int userId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Check if AuthController is available
      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      print('UserController: Attempting to fetch user $userId');
      print('UserController: Token status: ${token.isNotEmpty ? "Available (${token.length} chars)" : "Missing"}');
      
      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      // Show first and last few characters for debugging (but not the full token for security)
      if (token.length > 20) {
        print('UserController: Token preview: ${token.substring(0, 10)}...${token.substring(token.length - 10)}');
      }

      final userData = await _service.getUserById(userId: userId, token: token);
      user.value = userData;
      await fetchUserBlockStatus(userId);
      
      print('UserController: Successfully fetched user: ${userData.name} (${userData.email})');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      userBlockStatus.value = null;
      print('UserController: fetchUserById error: $e');
      
      // Don't show snackbar if it's a 404 (user might not exist)
      if (!e.toString().contains('404')) {
        Get.snackbar(
          "Error",
          "Failed to load user details",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } finally {
      isLoading.value = false;
    }
  }


  /// Update user details
  Future<bool> updateUser({
    required int userId,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      print('UserController: Updating user $userId');
      
      final updatedUser = await _service.updateUser(
        userId: userId,
        token: token,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );
      
      user.value = updatedUser;
      
      // Also update the global current user in AuthController
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        authController.updateCurrentUser(updatedUser);
      }
      
      print('UserController: Successfully updated user: ${updatedUser.name} (${updatedUser.email})');
      return true;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('UserController: updateUser error: $e');
      
      Get.snackbar(
        "Error",
        "Failed to update user details: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch current user details using JWT token
  Future<void> fetchCurrentUser() async {
    try {
      isLoadingCurrentUser.value = true;
      hasError.value = false;
      errorMessage.value = '';

      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      print('UserController: Attempting to fetch current user');
      print('UserController: Token status: ${token.isNotEmpty ? "Available (${token.length} chars)" : "Missing"}');
      
      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      final userData = await _service.getCurrentUser(token: token);
      currentUser.value = userData;
      
      print('UserController: Successfully fetched current user: ${userData.name} (${userData.email})');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('UserController: fetchCurrentUser error: $e');
      
      Get.snackbar(
        "Error",
        "Failed to load profile details",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoadingCurrentUser.value = false;
    }
  }

  /// Update current user details
  Future<bool> updateCurrentUser({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (currentUser.value == null) {
      Get.snackbar(
        "Error",
        "No user data available",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    }

    final success = await updateUser(
      userId: currentUser.value!.id,
      name: name,
      email: email,
      phone: phone,
      role: currentUser.value!.role,
    );

    if (success) {
      // Update currentUser as well
      currentUser.value = user.value;
      
      // Update global current user in AuthController
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        authController.updateCurrentUser(user.value!);
      }
      
      Get.snackbar(
        "Success",
        "Profile updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
    }

    return success;
  }

  /// Clear user data
  void clearUser() {
    user.value = null;
    currentUser.value = null;
    hasError.value = false;
    errorMessage.value = '';
    userBlockStatus.value = null;
    blockStatusError.value = '';
  }

  /// Fetch block status for a user
  Future<void> fetchUserBlockStatus(int userId) async {
    try {
      isLoadingBlockStatus.value = true;
      blockStatusError.value = '';

      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;
      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      final statusMap = await _service.getUserBlockStatus(userId: userId, token: token);
      userBlockStatus.value = BlockedUserStatus.fromJson(statusMap);
    } catch (e) {
      blockStatusError.value = e.toString();
      userBlockStatus.value = null;
      print('UserController: fetchUserBlockStatus error: $e');
    } finally {
      isLoadingBlockStatus.value = false;
    }
  }

  /// Block a user (admin action)
  /// Uses POST /api/admin/block-user/{user_id}.
  /// Returns true if backend reports success.
  Future<bool> blockUser(int userId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;
      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      final result = await _service.blockUser(userId: userId, token: token);
      final success = result['success'] == true;
      final message = result['message'] ?? 'User blocked.';

      if (success) {
        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
        userBlockStatus.value = BlockedUserStatus(
          userId: userId,
          isBlocked: true,
          blockedAt: DateTime.now(),
        );
        blockStatusError.value = '';
        await fetchUserById(userId);
      } else {
        Get.snackbar(
          'Info',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
      }
      return success;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('UserController: blockUser error: $e');
      Get.snackbar(
        'Error',
        'Failed to block user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Unblock a user (admin action)
  /// Uses POST /api/admin/unblock-user/{user_id}.
  /// Returns true if backend reports success.
  Future<bool> unblockUser(int userId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      if (!Get.isRegistered<AuthController>()) {
        throw Exception('Authentication controller not found. Please login first.');
      }

      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;
      if (token.isEmpty) {
        throw Exception('No authentication token available. Please login again.');
      }

      final result = await _service.unblockUser(userId: userId, token: token);
      final success = result['success'] == true;
      final message = result['message'] ?? 'User unblocked.';

      if (success) {
        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
        userBlockStatus.value = BlockedUserStatus(
          userId: userId,
          isBlocked: false,
          blockedAt: null,
        );
        blockStatusError.value = '';
        await fetchUserById(userId);
      } else {
        Get.snackbar(
          'Info',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
      }
      return success;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('UserController: unblockUser error: $e');
      Get.snackbar(
        'Error',
        'Failed to unblock user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

}