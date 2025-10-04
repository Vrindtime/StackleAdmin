import 'package:get/get.dart';
import 'package:stackle_admin/data/services/password_reset_service.dart';

class PasswordResetController extends GetxController {
  final PasswordResetService _service = PasswordResetService();

  // Loading states
  var isLoadingSendOTP = false.obs;
  var isLoadingResetPassword = false.obs;

  // Form states
  var email = ''.obs;
  var otp = ''.obs;
  var newPassword = ''.obs;
  var confirmPassword = ''.obs;

  // UI state
  var otpSent = false.obs;
  var resetSuccessful = false.obs;

  // Error handling
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  /// Send OTP to email
  Future<void> sendOTP() async {
    if (email.value.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!GetUtils.isEmail(email.value.trim())) {
      _showError('Please enter a valid email address');
      return;
    }

    try {
      isLoadingSendOTP.value = true;
      _clearMessages();

      final response = await _service.sendForgotPasswordOTP(email.value.trim());

      if (response.success) {
        otpSent.value = true;
        _showSuccess(response.message);
      } else {
        _showError(response.error ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showError('Failed to send OTP: ${e.toString()}');
    } finally {
      isLoadingSendOTP.value = false;
    }
  }

  /// Reset password with OTP
  Future<void> resetPassword() async {
    if (!_validateResetForm()) return;

    try {
      isLoadingResetPassword.value = true;
      _clearMessages();

      final response = await _service.resetPassword(
        email: email.value.trim(),
        otp: otp.value.trim(),
        newPassword: newPassword.value,
      );

      if (response.success) {
        resetSuccessful.value = true;
        _showSuccess(response.message);
        
        // Clear sensitive data
        _clearForm();
        
        // Navigate back to login after success
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed('/login');
        });
      } else {
        _showError(response.error ?? 'Failed to reset password');
      }
    } catch (e) {
      _showError('Failed to reset password: ${e.toString()}');
    } finally {
      isLoadingResetPassword.value = false;
    }
  }

  /// Validate reset password form
  bool _validateResetForm() {
    if (email.value.trim().isEmpty) {
      _showError('Email is required');
      return false;
    }

    if (!GetUtils.isEmail(email.value.trim())) {
      _showError('Please enter a valid email address');
      return false;
    }

    if (otp.value.trim().isEmpty) {
      _showError('OTP is required');
      return false;
    }

    if (otp.value.trim().length != 6) {
      _showError('OTP must be 6 digits');
      return false;
    }

    if (newPassword.value.isEmpty) {
      _showError('New password is required');
      return false;
    }

    if (newPassword.value.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }

    if (newPassword.value != confirmPassword.value) {
      _showError('Passwords do not match');
      return false;
    }

    return true;
  }

  /// Show error message
  void _showError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    successMessage.value = '';
    
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    hasError.value = false;
    errorMessage.value = '';
    successMessage.value = message;
    
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 3),
    );
  }

  /// Clear all messages
  void _clearMessages() {
    hasError.value = false;
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// Clear form data
  void _clearForm() {
    otp.value = '';
    newPassword.value = '';
    confirmPassword.value = '';
  }

  /// Reset controller state
  void resetState() {
    email.value = '';
    otp.value = '';
    newPassword.value = '';
    confirmPassword.value = '';
    otpSent.value = false;
    resetSuccessful.value = false;
    _clearMessages();
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    await sendOTP();
  }

  /// Go back to email step
  void goBackToEmailStep() {
    otpSent.value = false;
    otp.value = '';
    newPassword.value = '';
    confirmPassword.value = '';
    _clearMessages();
  }
}