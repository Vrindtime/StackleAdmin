import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/admin_chat_models.dart';

/// Service for client <-> organization chat API with admin endpoints.
class ClientChatService {
  /// Calls GET /admin/clients/{client_id}/conversations
  /// Requires an admin token passed in `token`.
  Future<ClientConversationsResponse> adminListClientConversations(String? token, int clientId) async {
  // Note: API routes for chat are under /chat/admin/... on the server
  final url = Uri.parse('$baseUrl/chat/admin/clients/$clientId/conversations');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

  final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 403) {
      throw Exception('Forbidden: admin access required');
    }
    if (resp.statusCode == 404) {
      // include response body when available to aid debugging
      final body = resp.body.isNotEmpty ? resp.body : null;
      throw Exception('Client not found${body != null ? ': $body' : ''}');
    }
    if (resp.statusCode != 200) {
      throw Exception('Failed to load conversations (status ${resp.statusCode}): ${resp.body}');
    }

    final dynamic body = json.decode(resp.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected response format from conversations endpoint: expected object');
    }

    return ClientConversationsResponse.fromJson(body);
  }

  /// Calls GET /admin/conversations/{conversation_id}/message
  /// Returns a list of MessageModel parsed from the admin compact format.
  Future<List<MessageModel>> adminGetConversationMessages(String? token, int conversationId) async {
  // Ensure /chat/ prefix matches server routes
  final url = Uri.parse('$baseUrl/chat/admin/conversations/$conversationId/message');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 403) {
      throw Exception('Forbidden: admin access required');
    }
    if (resp.statusCode == 404) {
      final body = resp.body.isNotEmpty ? resp.body : null;
      throw Exception('Conversation not found${body != null ? ': $body' : ''}');
    }
    if (resp.statusCode != 200) {
      throw Exception('Failed to load messages (status ${resp.statusCode}): ${resp.body}');
    }

    final dynamic body = json.decode(resp.body);
    if (body is! List) {
      throw Exception('Unexpected response format from messages endpoint: expected list');
    }

  return body
    .whereType<Map<String, dynamic>>()
    .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e)))
    .toList();
  }
}
