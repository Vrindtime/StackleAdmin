import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/data/models/user.dart';
import 'package:stackle_admin/core/api_base.dart';

class UserService {
  /// Get current user information using JWT token
  Future<User> getCurrentUser({required String token}) async {
    try {
      print('UserService: Fetching current user with JWT token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me-jwt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: me-jwt response status: ${response.statusCode}');
      print('UserService: me-jwt response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: getCurrentUser exception caught: $e');
      throw Exception('Failed to load current user details: $e');
    }
  }
  /// Get user details by user ID
  Future<User> getUserById({required int userId, required String token}) async {
    try {
      print('UserService: Fetching user $userId with token: ${token.isNotEmpty ? "Available (${token.length} chars)" : "Missing"}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: Response status: ${response.statusCode}');
      print('UserService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('User not found (404). Check if user ID $userId exists.');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: Exception caught: $e');
      throw Exception('Failed to load user details: $e');
    }
  }

  /// Update user details
  Future<User> updateUser({
    required int userId,
    required String token,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      print('UserService: Updating user $userId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/auth/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
        }),
      );

      print('UserService: Update response status: ${response.statusCode}');
      print('UserService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('User not found (404). Check if user ID $userId exists.');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: Update exception caught: $e');
      throw Exception('Failed to update user details: $e');
    }
  }

  /// Block a user by ID (admin privilege)
  /// Endpoint: POST /api/admin/block-user/{user_id}
  /// Returns: { success: bool, message: string }
  Future<Map<String, dynamic>> blockUser({required int userId, required String token}) async {
    try {
      print('UserService: Blocking user $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/block-user/$userId'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: blockUser response status: ${response.statusCode}');
      print('UserService: blockUser response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'User blocked.',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else if (response.statusCode == 404) {
        throw Exception('User not found (404).');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: blockUser exception: $e');
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user by ID (admin privilege)
  /// Endpoint: POST /api/admin/unblock-user/{user_id}
  /// Returns: { success: bool, message: string }
  Future<Map<String, dynamic>> unblockUser({required int userId, required String token}) async {
    try {
      print('UserService: Unblocking user $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/unblock-user/$userId'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: unblockUser response status: ${response.statusCode}');
      print('UserService: unblockUser response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'User unblocked.',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else if (response.statusCode == 404) {
        throw Exception('User not found (404).');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: unblockUser exception: $e');
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Get block status for a user
  /// Endpoint: GET /api/admin/block-status/{user_id}
  /// Success (200): { "user_id": int, "is_blocked": bool, "blocked_at": isoString|null }
  Future<Map<String, dynamic>> getUserBlockStatus({required int userId, required String token}) async {
    try {
      print('UserService: Fetching block status for user $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/block-status/$userId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: getUserBlockStatus status: ${response.statusCode}');
      print('UserService: getUserBlockStatus body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'user_id': data['user_id'] ?? userId,
          'is_blocked': data['is_blocked'] ?? false,
          'blocked_at': data['blocked_at'],
        };
      } else if (response.statusCode == 404) {
        // Some backends return 404 when the user has no block history yet.
        // Treat this as "not blocked" so the UI can function without errors.
        String message = '';
        try {
          final body = json.decode(response.body);
          if (body is Map<String, dynamic>) {
            message = (body['detail'] ?? body['message'] ?? '').toString();
          }
        } catch (_) {
          // ignore JSON parsing errors for graceful fallback
        }

    final normalized = message.toLowerCase();
    final looksLikeNoRecord = normalized.contains('block') ||
      normalized.contains('no record') ||
      normalized.contains('no entry');

        if (looksLikeNoRecord || message.isEmpty) {
          return {
            'user_id': userId,
            'is_blocked': false,
            'blocked_at': null,
          };
        }

        throw Exception('User not found (404). $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: getUserBlockStatus exception: $e');
      throw Exception('Failed to fetch user block status: $e');
    }
  }

  /// List all blocked users
  /// Endpoint: GET /api/admin/blocked-users
  /// Success (200): [ { "user_id": int, "blocked_at": isoString }, ... ]
  Future<List<Map<String, dynamic>>> getBlockedUsers({required String token}) async {
    try {
      print('UserService: Fetching blocked users list');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/blocked-users'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: getBlockedUsers status: ${response.statusCode}');
      print('UserService: getBlockedUsers body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          // Preserve nested user/client objects as provided by backend
          return data.cast<Map<String, dynamic>>();
        }
        throw Exception('Unexpected response format for blocked users list (expected List)');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: getBlockedUsers exception: $e');
      throw Exception('Failed to fetch blocked users: $e');
    }
  }

  /// Block an organisation by ID (admin privilege)
  /// Endpoint: POST /api/admin/block-organisation/{organisation_id}
  /// Returns: { success: bool, message: string }
  Future<Map<String, dynamic>> blockOrganisation({required int organisationId, required String token}) async {
    try {
      print('UserService: Blocking organisation $organisationId');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/block-organisation/$organisationId'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: blockOrganisation status: ${response.statusCode}');
      print('UserService: blockOrganisation body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Organisation blocked.',
        };
      } else if (response.statusCode == 404) {
        throw Exception('Organisation not found (404).');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: blockOrganisation exception: $e');
      throw Exception('Failed to block organisation: $e');
    }
  }

  /// Unblock an organisation by ID
  /// Endpoint: POST /api/admin/unblock-organisation/{organisation_id}
  Future<Map<String, dynamic>> unblockOrganisation({required int organisationId, required String token}) async {
    try {
      print('UserService: Unblocking organisation $organisationId');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/unblock-organisation/$organisationId'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: unblockOrganisation status: ${response.statusCode}');
      print('UserService: unblockOrganisation body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Organisation unblocked.',
        };
      } else if (response.statusCode == 404) {
        throw Exception('Organisation not found (404).');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: unblockOrganisation exception: $e');
      throw Exception('Failed to unblock organisation: $e');
    }
  }

  /// Get block status for an organisation
  /// Endpoint: GET /api/admin/block-status/organisation/{organisation_id}
  Future<Map<String, dynamic>> getOrganisationBlockStatus({required int organisationId, required String token}) async {
    try {
      print('UserService: Fetching organisation block status $organisationId');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/block-status/organisation/$organisationId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: getOrganisationBlockStatus status: ${response.statusCode}');
      print('UserService: getOrganisationBlockStatus body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'organisation_id': data['organisation_id'] ?? organisationId,
          'is_blocked': data['is_blocked'] ?? false,
          'blocked_at': data['blocked_at'],
        };
      } else if (response.statusCode == 404) {
        throw Exception('Organisation not found (404).');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: getOrganisationBlockStatus exception: $e');
      throw Exception('Failed to fetch organisation block status: $e');
    }
  }

  /// List all blocked organisations
  /// Endpoint: GET /api/admin/blocked-organisations
  Future<List<Map<String, dynamic>>> getBlockedOrganisations({required String token}) async {
    try {
      print('UserService: Fetching blocked organisations list');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/blocked-organisations'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserService: getBlockedOrganisations status: ${response.statusCode}');
      print('UserService: getBlockedOrganisations body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        throw Exception('Unexpected response format for blocked organisations list (expected List)');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401). Token may be invalid or expired.');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('UserService: getBlockedOrganisations exception: $e');
      throw Exception('Failed to fetch blocked organisations: $e');
    }
  }
}