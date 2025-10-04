import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/admin_totals.dart';

class StatsService {
  Future<AdminTotals> fetchAdminTotals({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin/total');

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return AdminTotals.fromJson(jsonData);
      } else {
        print('DEBUG: fetchAdminTotals failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to load admin totals');
      }
    } catch (e) {
      print('DEBUG: fetchAdminTotals error: $e');
      rethrow;
    }
  }
}