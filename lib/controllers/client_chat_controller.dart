import 'package:get/get.dart';
import 'package:stackle_admin/data/services/client_chat_service.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/models/admin_chat_models.dart';

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
      String? token;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        await auth.checkAndRefreshToken();
        token = auth.accessToken.value;
      }

      final ClientConversationsResponse resp = await _service.adminListClientConversations(token, id);
      // debug
      try {
        print('ClientChatController: fetched ${resp.conversations.length} conversations for client ${resp.client.id}');
      } catch (_) {}
      conversations.clear();
      // Convert typed models to map shape expected by existing UI
      for (final c in resp.conversations) {
        conversations.add({
          'id': c.id,
          'organization': {
            'id': c.organization.id,
            'name': c.organization.name,
            'logo': c.organization.avatar ?? '',
            'avatar': c.organization.avatar ?? '',
          },
          'last_message': c.lastMessageText ?? '',
          'last_message_text': c.lastMessageText,
          'last_message_timestamp': c.lastMessageTimestamp?.toIso8601String(),
          'updated_at': c.updatedAt.toIso8601String(),
          'is_blocked': c.isBlocked,
          'isBlocked': c.isBlocked,
          'blocked_by': c.blockedBy,
        });
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
      String? token;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        await auth.checkAndRefreshToken();
        token = auth.accessToken.value;
      }

      final List<MessageModel> res = await _service.adminGetConversationMessages(token, conversationId);
      messages
        ..clear()
        ..addAll(res.map((m) => {
          'id': m.id,
          'message': m.text ?? '',
          'text': m.text ?? '',
          'message_type': m.messageType,
          'file_url': m.fileUrl,
          'sent_at': m.timestamp.toIso8601String(),
          'timestamp_ms': m.timestampMs,
          'sender_user_id': m.senderUserId,
          'sender_name': m.senderName,
          'sender_type': m.senderType,
          'sender_entity_id': m.senderEntityId,
          'sender_avatar': m.senderAvatar,
          'is_deleted': m.isDeleted,
          'read_at': m.readAt?.toIso8601String(),
        }).toList());
    } catch (e) {
      messagesError.value = e.toString();
      messages.clear();
    } finally {
      isLoadingMessages.value = false;
    }
  }
}
