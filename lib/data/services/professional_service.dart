import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/client.dart';

class ProfessionalService {
  /// GET /api/clients/{client_id} - Fetch specific client by ID
  Future<Client> getClientById(int clientId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/clients/$clientId');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return Client.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Client not found (404). Check if client ID $clientId exists.');
      } else {
        print('DEBUG: getClientById failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to fetch client: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: getClientById error: $e');
      rethrow;
    }
  }

  /// GET /api/clients/ - Fetch all clients/professionals
  Future<List<Client>> getAllClients({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/clients/');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Client.fromJson(json)).toList();
      } else {
        print('DEBUG: getAllClients failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to fetch clients: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: getAllClients error: $e');
      rethrow;
    }
  }

  /// GET /api/admin-approval/clients/approved - Fetch approved clients
  Future<List<Client>> getApprovedClients({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin-approval/clients/approved');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Client.fromJson(json)).toList();
      } else {
        print('DEBUG: getApprovedClients failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to fetch approved clients: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: getApprovedClients error: $e');
      rethrow;
    }
  }

  /// GET /api/admin-approval/clients/pending-approval - Fetch pending approval clients
  Future<List<Client>> getPendingApprovalClients({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin-approval/clients/pending-approval');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Client.fromJson(json)).toList();
      } else {
        print('DEBUG: getPendingApprovalClients failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to fetch pending clients: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: getPendingApprovalClients error: $e');
      rethrow;
    }
  }

  /// POST /api/admin-approval/clients/{client_id}/approve - Approve a client
  Future<bool> approveClient(int clientId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin-approval/clients/$clientId/approve');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('DEBUG: approveClient failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to approve client: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: approveClient error: $e');
      rethrow;
    }
  }

  /// PATCH /api/admin-approval/clients/{client_id}/approval-status - Update approval status
  Future<bool> updateApprovalStatus(int clientId, bool isApproved, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin-approval/clients/$clientId/approval-status');
      final headers = <String, String>{'Content-Type': 'application/x-www-form-urlencoded'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = 'is_approved=${isApproved.toString()}';
      final response = await http.patch(url, headers: headers, body: body);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('DEBUG: updateApprovalStatus failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to update approval status: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: updateApprovalStatus error: $e');
      rethrow;
    }
  }

  /// POST /api/admin-approval/clients/bulk-approve - Bulk approve clients
  Future<bool> bulkApproveClients(List<int> clientIds, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/admin-approval/clients/bulk-approve');
      final headers = <String, String>{'Content-Type': 'application/x-www-form-urlencoded'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Convert list to form-encoded format
      final clientIdsString = clientIds.join(',');
      final body = 'client_ids=$clientIdsString';
      
      final response = await http.post(url, headers: headers, body: body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('DEBUG: bulkApproveClients failed: ${response.body}, status code: ${response.statusCode}');
        throw Exception('Failed to bulk approve clients: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: bulkApproveClients error: $e');
      rethrow;
    }
  }

  /// Reject a client (using updateApprovalStatus with false)
  Future<bool> rejectClient(int clientId, {String? token}) async {
    return updateApprovalStatus(clientId, false, token: token);
  }

  /// Update client profile data
  Future<bool> updateClientProfile({
    required int clientId,
    required String token,
    required String preferredJob,
    required String description,
    required String place,
    required String district,
    required String state,
    required String pincode,
  }) async {
    try {
      final clientRequest = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/clients/$clientId'),
      );
      
      clientRequest.headers['Authorization'] = 'Bearer $token';
      clientRequest.fields.addAll({
        'preferred_job': preferredJob,
        'description': description,
        'place': place,
        'district': district,
        'state': state,
        'pincode': pincode,
      });

      final clientStreamedResponse = await clientRequest.send();
      final clientResponse = await http.Response.fromStream(clientStreamedResponse);

      print('ProfessionalService: Update client response status: ${clientResponse.statusCode}');
      print('ProfessionalService: Update client response body: ${clientResponse.body}');

      if (clientResponse.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update client: ${clientResponse.body}');
      }
    } catch (e) {
      print('ProfessionalService: updateClientProfile error: $e');
      rethrow;
    }
  }
}