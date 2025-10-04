import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/feedback_model.dart';

class FeedbackService {
  /// Fetches all feedbacks from the API
  /// Returns a list of FeedbackModel objects
  Future<List<FeedbackModel>> getFeedbacks({String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/feedbacks/");
      
      // Prepare headers
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };
      
      // Add authorization header if token is provided
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => FeedbackModel.fromJson(json)).toList();
      } else {
        print("DEBUG: Get feedbacks failed: ${response.body}, status code: ${response.statusCode}");
        throw Exception("Failed to fetch feedbacks: Status code ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Get feedbacks error: $e");
      throw Exception("Error fetching feedbacks: $e");
    }
  }

  /// Fetches a specific feedback by ID
  Future<FeedbackModel?> getFeedbackById(int id, {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/feedbacks/$id/");
      
      // Prepare headers
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };
      
      // Add authorization header if token is provided
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return FeedbackModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null; // Feedback not found
      } else {
        print("DEBUG: Get feedback by ID failed: ${response.body}, status code: ${response.statusCode}");
        throw Exception("Failed to fetch feedback: Status code ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Get feedback by ID error: $e");
      throw Exception("Error fetching feedback: $e");
    }
  }

  /// Updates a specific feedback by ID
  /// PUT /api/feedbacks/{feedback_id}
  Future<FeedbackModel?> updateFeedback(
    int feedbackId, 
    String subject, 
    String message, 
    {String? token}
  ) async {
    try {
      final url = Uri.parse("$baseUrl/feedbacks/$feedbackId/");
      
      // Prepare headers
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };
      
      // Add authorization header if token is provided
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.put(
        url, 
        headers: headers,
        body: jsonEncode({
          "subject": subject,
          "message": message,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return FeedbackModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception("Feedback not found");
      } else {
        print("DEBUG: Update feedback failed: ${response.body}, status code: ${response.statusCode}");
        throw Exception("Failed to update feedback: Status code ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Update feedback error: $e");
      throw Exception("Error updating feedback: $e");
    }
  }

  /// Deletes a specific feedback by ID
  /// DELETE /api/feedbacks/{feedback_id}
  Future<bool> deleteFeedback(int feedbackId, {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/feedbacks/$feedbackId/");
      
      // Prepare headers
      Map<String, String> headers = {
        "Content-Type": "application/json",
      };
      
      // Add authorization header if token is provided
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true; // Successfully deleted
      } else if (response.statusCode == 404) {
        throw Exception("Feedback not found");
      } else {
        print("DEBUG: Delete feedback failed: ${response.body}, status code: ${response.statusCode}");
        throw Exception("Failed to delete feedback: Status code ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Delete feedback error: $e");
      throw Exception("Error deleting feedback: $e");
    }
  }
}