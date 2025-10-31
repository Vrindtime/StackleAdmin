import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/core/api_base.dart';

class ChatService {
  final AuthController _auth = Get.find<AuthController>();

  /// Fetch conversations for an organization.
  /// Expects { organization, conversations } response. Returns a map with keys:
  /// { 'organization': Map<String,dynamic>? , 'conversations': List<dynamic> }
  Future<Map<String, dynamic>> fetchConversationsForOrg(int orgId) async {
    final url = Uri.parse('$baseUrl/chat/admin/organizations/$orgId/conversations');

    final headers = {
      'Authorization': 'Bearer ${_auth.accessToken.value}',
    };

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 401) {
      // Let caller/upper layers decide, but attempt token refresh to surface a clearer error
      await _auth.checkAndRefreshToken();
      throw Exception('Authentication required');
    }

    if (resp.statusCode != 200) {
      throw Exception('Failed to load conversations (status ${resp.statusCode})');
    }

    final dynamic body = json.decode(resp.body);

    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected response format from conversations endpoint: expected object');
    }

    final organization = (body['organization'] is Map) ? Map<String, dynamic>.from(body['organization']) : null;
    final conversations = (body['conversations'] is List) ? (body['conversations'] as List<dynamic>) : null;

    if (conversations == null) {
      throw Exception('Missing "conversations" array in response');
    }

    return {'organization': organization, 'conversations': conversations};
  }

  /// Fetch full message history for a conversation by its ID.
  /// Returns a list of maps, each representing a chat message.
  Future<List<Map<String, dynamic>>> fetchMessagesForConversation(int conversationId) async {
    final url = Uri.parse('$baseUrl/chat/admin/conversations/$conversationId/message');

    final headers = {
      'Authorization': 'Bearer ${_auth.accessToken.value}',
    };

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 401) {
      await _auth.checkAndRefreshToken();
      throw Exception('Authentication required');
    }

    if (resp.statusCode != 200) {
      throw Exception('Failed to load messages (status ${resp.statusCode})');
    }

    final dynamic body = json.decode(resp.body);

    if (body is! List) {
      throw Exception('Unexpected response format from messages endpoint: expected list');
    }

    return body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}