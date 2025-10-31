import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/services/org_chat_service.dart';

class OrgChatController extends GetxController {

  final OrgChatService _service = OrgChatService();

  // local organization id (the "current" org from which we decide message origin)
  final RxnInt localOrgId = RxnInt();

  // store remote organization as plain JSON so we don't have to construct a full model
  final Rxn<Map<String, dynamic>> organization = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString messagesError = RxnString();

  void setLocalOrgId(int? id) {
    if (id == null) return;
    localOrgId.value = id;
  }

  Future<void> fetchConversations(int orgId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final auth = Get.find<AuthController>();
      await auth.checkAndRefreshToken();

      final res = await _service.fetchConversationsForOrg(orgId);
      final orgMap = res['organization'];
      if (orgMap != null && orgMap is Map) {
        organization.value = Map<String, dynamic>.from(orgMap);
      }

      final convs = res['conversations'];
      conversations.clear();
      if (convs is List) {
        for (final c in convs) {
          if (c is Map<String, dynamic>) {
            conversations.add(c);
          } else if (c is Map) {
            conversations.add(Map<String, dynamic>.from(c));
          }
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    isLoadingMessages.value = true;
    messagesError.value = null;
    try {
      final auth = Get.find<AuthController>();
      await auth.checkAndRefreshToken();

      final result = await _service.fetchMessagesForConversation(conversationId);
      messages
        ..clear()
        ..addAll(result);
    } catch (e) {
      messagesError.value = e.toString();
      messages.clear();
    } finally {
      isLoadingMessages.value = false;
    }
  }
}
