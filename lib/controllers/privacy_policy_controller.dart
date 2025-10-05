import 'package:get/get.dart';
import 'package:stackle_admin/data/models/privacy_policy.dart';
import 'package:stackle_admin/data/services/privacy_policy_service.dart';

class PrivacyPolicyController extends GetxController {
  PrivacyPolicyController({PrivacyPolicyService? service})
      : _service = service ?? PrivacyPolicyService();

  final PrivacyPolicyService _service;

  final Rxn<PrivacyPolicy> policy = Rxn<PrivacyPolicy>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> loadPrivacyPolicy() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.fetchPrivacyPolicy();
      policy.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load privacy policy',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createPrivacyPolicy(String text) async {
    if (text.trim().isEmpty) {
      Get.snackbar(
        'Validation error',
        'Privacy policy text cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.createPrivacyPolicy(text.trim());
      policy.value = result.policy;

      Get.snackbar(
        'Success',
        result.message ?? 'Privacy policy saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return result.success;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to create privacy policy',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updatePrivacyPolicy(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        'Validation error',
        'Privacy policy text cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updatePrivacyPolicy(text: trimmed);
      policy.value = result.policy;

      Get.snackbar(
        'Success',
        result.message ?? 'Privacy policy updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return result.success;
    } on PrivacyPolicyNotFoundException catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Create required',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      policy.value = null;
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update privacy policy',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void clear() {
    policy.value = null;
    errorMessage.value = '';
  }
}
