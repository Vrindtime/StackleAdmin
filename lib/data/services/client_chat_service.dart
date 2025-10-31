import 'dart:convert';
import 'package:get/get.dart';
// import 'package:http/http.dart' as http; // enable when implementing API calls
import 'package:stackle_admin/core/api_base.dart';
// import 'package:stackle_admin/controllers/auth_controller.dart';

/// Placeholder service for client <-> organization chat API.
///
/// Implement the real HTTP calls when the API is ready. For now these
/// methods return empty data structures so the UI can be wired up.
class ClientChatService {
  // final AuthController _auth = Get.find<AuthController>();

  /// Returns a list of conversation objects for the given client id.
  /// Expected server shape: List<Map<String,dynamic>> where each item contains
  /// conversation id, org info and summary fields.
  Future<List<dynamic>> fetchConversationsForClient(int clientId) async {
    // TODO: replace with real HTTP request
    // final url = Uri.parse('$baseUrl/chat/clients/$clientId/conversations');
    // final resp = await http.get(url, headers: { 'Authorization': 'Bearer \\${_auth.accessToken.value}' });
    // if (resp.statusCode != 200) throw Exception('Failed to load');
    // final body = json.decode(resp.body);
    // return (body as List).cast<dynamic>();

    await Future.delayed(const Duration(milliseconds: 250));
    return <dynamic>[]; // placeholder empty list
  }

  /// Returns messages for a single conversation id.
  Future<List<dynamic>> fetchMessagesForConversation(int conversationId) async {
    // TODO: replace with real HTTP request
    // final url = Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');
    // final resp = await http.get(url, headers: { 'Authorization': 'Bearer \\${_auth.accessToken.value}' });
    // if (resp.statusCode != 200) throw Exception('Failed to load messages');
    // final body = json.decode(resp.body);
    // return (body as List).cast<dynamic>();

    await Future.delayed(const Duration(milliseconds: 250));
    return <dynamic>[]; // placeholder
  }
}
