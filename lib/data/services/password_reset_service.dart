import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/password_reset.dart';

class PasswordResetService {
  final String _baseUrl = baseUrl;

  /// Send OTP to email for password reset
  Future<ForgotPasswordResponse> sendForgotPasswordOTP(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/forgot-email/');
      
      final request = ForgotPasswordRequest(email: email);
      
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: request.toFormData(),
      );

      print('ForgotPassword API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ForgotPasswordResponse.fromJson(data);
      } else {
        // Try to parse error response
        try {
          final data = json.decode(response.body);
          return ForgotPasswordResponse.fromJson(data);
        } catch (e) {
          return ForgotPasswordResponse(
            success: false,
            message: '',
            error: 'Failed to send OTP. Status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('ForgotPassword Service Error: $e');
      return ForgotPasswordResponse(
        success: false,
        message: '',
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Reset password using OTP
  Future<ResetPasswordResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/auth/reset-password/');
      
      final request = ResetPasswordRequest(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: request.toFormData(),
      );

      print('ResetPassword API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResetPasswordResponse.fromJson(data);
      } else {
        // Try to parse error response
        try {
          final data = json.decode(response.body);
          return ResetPasswordResponse.fromJson(data);
        } catch (e) {
          return ResetPasswordResponse(
            success: false,
            message: '',
            error: 'Failed to reset password. Status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('ResetPassword Service Error: $e');
      return ResetPasswordResponse(
        success: false,
        message: '',
        error: 'Network error: ${e.toString()}',
      );
    }
  }
}