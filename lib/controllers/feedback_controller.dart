import 'package:get/get.dart';
import 'package:stackle_admin/data/models/feedback_model.dart';
import 'package:stackle_admin/data/services/feedback_service.dart';
import 'package:stackle_admin/controllers/auth_controller.dart';

class FeedbackController extends GetxController {
  final FeedbackService _feedbackService = FeedbackService();
  
  // Observable list of feedbacks
  var feedbacks = <FeedbackModel>[].obs;
  
  // Loading states
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  
  // Error handling
  var errorMessage = ''.obs;
  var hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load feedbacks when controller initializes
    fetchFeedbacks();
  }

  /// Fetches feedbacks from the API
  Future<void> fetchFeedbacks({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
      
      hasError.value = false;
      errorMessage.value = '';

      // Get auth token from AuthController
      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken(); // Ensure token is valid
      
      final token = authController.accessToken.value;
      
      final fetchedFeedbacks = await _feedbackService.getFeedbacks(token: token);
      
      feedbacks.assignAll(fetchedFeedbacks);
      
      print('FeedbackController: Successfully fetched ${fetchedFeedbacks.length} feedbacks');
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      
      print('FeedbackController: Error fetching feedbacks - $e');
      
      // Show error snackbar
      Get.snackbar(
        "Error",
        "Failed to load feedbacks: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } finally {
      if (isRefresh) {
        isRefreshing.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  /// Refreshes the feedback list
  Future<void> refreshFeedbacks() async {
    await fetchFeedbacks(isRefresh: true);
  }

  /// Gets a specific feedback by ID
  Future<FeedbackModel?> getFeedbackById(int id) async {
    try {
      // Get auth token from AuthController
      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken(); // Ensure token is valid
      
      final token = authController.accessToken.value;
      
      return await _feedbackService.getFeedbackById(id, token: token);
      
    } catch (e) {
      print('FeedbackController: Error fetching feedback by ID - $e');
      
      Get.snackbar(
        "Error",
        "Failed to load feedback: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return null;
    }
  }

  /// Returns the number of feedbacks
  int get feedbackCount => feedbacks.length;

  /// Checks if there are any feedbacks
  bool get hasFeedbacks => feedbacks.isNotEmpty;

  /// Gets feedbacks sorted by creation date (newest first)
  List<FeedbackModel> get sortedFeedbacks {
    final sortedList = List<FeedbackModel>.from(feedbacks);
    sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedList;
  }

  /// Updates a specific feedback
  Future<bool> updateFeedback(int feedbackId, String subject, String message) async {
    try {
      // Get auth token from AuthController
      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken(); // Ensure token is valid
      
      final token = authController.accessToken.value;
      
      final updatedFeedback = await _feedbackService.updateFeedback(
        feedbackId, 
        subject, 
        message, 
        token: token
      );
      
      if (updatedFeedback != null) {
        // Update the feedback in the local list
        final index = feedbacks.indexWhere((feedback) => feedback.id == feedbackId);
        if (index != -1) {
          feedbacks[index] = updatedFeedback;
        }
        
        print('FeedbackController: Successfully updated feedback $feedbackId');
        
        Get.snackbar(
          "Success",
          "Feedback updated successfully",
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('FeedbackController: Error updating feedback - $e');
      
      Get.snackbar(
        "Error",
        "Failed to update feedback: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return false;
    }
  }

  /// Deletes a specific feedback
  Future<bool> deleteFeedback(int feedbackId) async {
    try {
      // Get auth token from AuthController
      final authController = Get.find<AuthController>();
      await authController.checkAndRefreshToken(); // Ensure token is valid
      
      final token = authController.accessToken.value;
      
      final success = await _feedbackService.deleteFeedback(feedbackId, token: token);
      
      if (success) {
        // Remove the feedback from the local list
        feedbacks.removeWhere((feedback) => feedback.id == feedbackId);
        
        print('FeedbackController: Successfully deleted feedback $feedbackId');
        
        Get.snackbar(
          "Success",
          "Feedback deleted successfully",
          snackPosition: SnackPosition.BOTTOM,
        );
        
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('FeedbackController: Error deleting feedback - $e');
      
      Get.snackbar(
        "Error",
        "Failed to delete feedback: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return false;
    }
  }
}