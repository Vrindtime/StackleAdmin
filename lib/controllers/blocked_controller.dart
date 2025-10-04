import 'package:get/get.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';
import 'package:stackle_admin/data/services/user_service.dart';

/// Controller dedicated for managing blocked users and organisations.
class BlockedController extends GetxController {
  final _service = UserService();

  // Reactive state
  var isLoadingUsers = false.obs;
  var isLoadingOrgs = false.obs;
  var userError = ''.obs;
  var orgError = ''.obs;

  // Each element now preserves full backend payload including nested 'user', 'client'
  // Example user item: { user_id, blocked_at, user: {...}, client: {...}? }
  var blockedUsers = <Map<String, dynamic>>[].obs;
  // Example organisation item: { organisation_id, blocked_at, organisation: {...} }
  var blockedOrganisations = <Map<String, dynamic>>[].obs;

  // Cache maps for status lookups if needed later
  final Map<int, Map<String, dynamic>> _userStatusCache = {};
  final Map<int, Map<String, dynamic>> _orgStatusCache = {};

  AuthController get _auth => Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    // Initial fetch
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchBlockedUsers(),
      fetchBlockedOrganisations(),
    ]);
  }

  Future<void> fetchBlockedUsers() async {
    try {
      isLoadingUsers.value = true;
      userError.value = '';
      await _auth.checkAndRefreshToken();
      final token = _auth.accessToken.value;
      final list = await _service.getBlockedUsers(token: token);
      blockedUsers.assignAll(list);
    } catch (e) {
      userError.value = e.toString();
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> fetchBlockedOrganisations() async {
    try {
      isLoadingOrgs.value = true;
      orgError.value = '';
      await _auth.checkAndRefreshToken();
      final token = _auth.accessToken.value;
      final list = await _service.getBlockedOrganisations(token: token);
      blockedOrganisations.assignAll(list);
    } catch (e) {
      orgError.value = e.toString();
    } finally {
      isLoadingOrgs.value = false;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      await _auth.checkAndRefreshToken();
      final token = _auth.accessToken.value;
      final result = await _service.unblockUser(userId: userId, token: token);
      if (result['success'] == true) {
        blockedUsers.removeWhere((e) => e['user_id'] == userId);
        _userStatusCache[userId] = {'user_id': userId, 'is_blocked': false, 'blocked_at': null};
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockOrganisation(int organisationId) async {
    try {
      await _auth.checkAndRefreshToken();
      final token = _auth.accessToken.value;
      final result = await _service.unblockOrganisation(organisationId: organisationId, token: token);
      if (result['success'] == true) {
        blockedOrganisations.removeWhere((e) => e['organisation_id'] == organisationId);
        _orgStatusCache[organisationId] = {'organisation_id': organisationId, 'is_blocked': false, 'blocked_at': null};
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
