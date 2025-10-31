import 'package:get/get.dart';
import 'package:stackle_admin/data/services/client_chat_service.dart';

/// Controller for client <-> organization chats (simple flows).
/// This is a placeholder implementation — wire up API in `ClientChatService` later.
class ClientChatController extends GetxController {
  final ClientChatService _service = ClientChatService();

  final RxnInt clientId = RxnInt();
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString messagesError = RxnString();

  /// Fetch conversations for a client (conversations between the client and organizations)
  Future<void> fetchConversationsForClient(int id) async {
    isLoading.value = true;
    errorMessage.value = null;
    clientId.value = id;
    try {
      final res = await _service.fetchConversationsForClient(id);
      conversations.clear();
      if (res is List) {
        conversations.addAll(res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch messages for a specific conversation
  Future<void> fetchMessagesForConversation(int conversationId) async {
    isLoadingMessages.value = true;
    messagesError.value = null;
    try {
      final res = await _service.fetchMessagesForConversation(conversationId);
      messages
        ..clear()
        ..addAll(res.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    } catch (e) {
      messagesError.value = e.toString();
      messages.clear();
    } finally {
      isLoadingMessages.value = false;
    }
  }
}
