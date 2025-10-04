class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, String> toFormData() {
    return {'email': email};
  }
}

class ForgotPasswordResponse {
  final bool success;
  final String message;
  final String? error;

  ForgotPasswordResponse({
    required this.success,
    required this.message,
    this.error,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  Map<String, String> toFormData() {
    return {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    };
  }
}

class ResetPasswordResponse {
  final bool success;
  final String message;
  final String? error;

  ResetPasswordResponse({
    required this.success,
    required this.message,
    this.error,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}