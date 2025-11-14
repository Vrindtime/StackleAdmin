import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "role": "admin",
        "device_id": "admin-web"
      }), // Added device_id
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          "DEBUG: Login failed: ${response.body} , status code: ${response.statusCode}");
      throw Exception(
          "Login failed: Check your credentials , status code: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final url = Uri.parse("$baseUrl/auth/refresh");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $refreshToken",
        },
        body: jsonEncode({"refresh": refreshToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            "DEBUG: Token refresh failed: ${response.body}, status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("DEBUG: Token refresh error: $e");
      return null;
    }
  }
}
