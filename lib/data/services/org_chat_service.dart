
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/core/api_base.dart';

class OrgChatService{
  final AuthController _auth = Get.find<AuthController>();

  Future<Map<String, dynamic>> fetchConversationsForOrg(int orgId) async {
    final url = Uri.parse('$baseUrl/orgchat/admin/organizations/$orgId/conversations');

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
    final url = Uri.parse('$baseUrl/orgchat/admin/organizations/$conversationId/conversations/messages');

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
    // Delegate parsing to a helper for clarity and testability.
    return _extractMessagesList(body, conversationId);
  }

  // Helper: extract a list of message maps from the decoded JSON body.
  // The API sometimes returns { "<conversationId>": [ ... ] } or a plain list.
  List<Map<String, dynamic>> _extractMessagesList(dynamic body, int conversationId) {
    // Case A: body is a map, e.g. { "10": [ ... ] }
    if (body is Map<String, dynamic>) {
      final String key = conversationId.toString();

      // Prefer the explicit conversation key when present.
      dynamic rawList = body.containsKey(key) ? body[key] : null;

      // Common server behaviour: return a single-key map. If no explicit key,
      // take the first value when the response has only one entry.
      rawList ??= (body.length == 1) ? body.values.first : null;

      // As a final fallback, find the first value that is a List.
      rawList ??= body.values.firstWhere((v) => v is List, orElse: () => null);

      if (rawList == null || rawList is! List) {
        throw Exception('Unexpected messages payload: expected a List of messages for conversation $key');
      }

      // Normalize each item to Map<String, dynamic> and filter out anything else.
      final List<Map<String, dynamic>> out = rawList.where((e) => e is Map).map((e) {
        if (e is Map<String, dynamic>) return e;
        return Map<String, dynamic>.from(e as Map);
      }).toList();

      return out;
    }

    // Case B: body is already a list of messages.
    if (body is List) {
      return body.where((e) => e is Map).map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)).toList();
    }

    // Unexpected shape
    throw Exception('Unexpected response format from messages endpoint');
  }





}