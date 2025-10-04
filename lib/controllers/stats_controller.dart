import 'package:get/get.dart';
import 'package:stackle_admin/data/models/admin_totals.dart';
import 'package:stackle_admin/data/services/stats_service.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class StatsController extends GetxController {
  final StatsService _service = StatsService();

  var totals = AdminTotals(totalJobProviders: 0, totalJobSeekers: 0, totalVacancies: 0, totalPendingRequests: 0).obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTotals();
  }

  Future<void> fetchTotals() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // ensure auth tokens are valid
      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken();
      final token = authController.accessToken.value;

      final result = await _service.fetchAdminTotals(token: token);
      totals.value = result;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('StatsController: fetchTotals error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
