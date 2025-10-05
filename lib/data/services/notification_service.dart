import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/push_notification.dart';

class NotificationService {
  NotificationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Sends a push notification to the backend.
  ///
  /// Expects the backend to honour the following payload contract:
  /// ```json
  /// {
  ///   "title": "...",
  ///   "message": "...",
  ///   "broadcast": true,
  ///   "user_ids": [1, 2, 3]
  /// }
  /// ```
  /// When `broadcast` is true the `user_ids` key is ignored and notifications
  /// are sent to every available device. When `broadcast` is false the backend
  /// targets the provided `user_ids` list.
  Future<SendNotificationResult> sendNotification({
    required String token,
    required PushNotificationRequest request,
  }) async {
    final uniqueRecipientIds = request.recipientIds.toSet().toList();

    if (request.broadcastToAll) {
      return _sendBulkNotifications(
        token: token,
        request: request,
        recipientIds: uniqueRecipientIds,
      );
    }

    if (uniqueRecipientIds.isEmpty) {
      return _sendSelfNotification(token: token, request: request);
    }

    return _sendBulkNotifications(
      token: token,
      request: request,
      recipientIds: uniqueRecipientIds,
    );
  }

  Future<SendNotificationResult> _sendSelfNotification({
    required String token,
    required PushNotificationRequest request,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    final decodedBody = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decodedBody is Map<String, dynamic>) {
        return SendNotificationResult.fromJson(decodedBody);
      }
      return const SendNotificationResult(
        success: true,
        message: 'Notification created successfully',
        notification: null,
      );
    }

    final errorMessage = _extractErrorMessage(decodedBody, response.statusCode);
    throw NotificationException(errorMessage, statusCode: response.statusCode);
  }

  Future<SendNotificationResult> _sendBulkNotifications({
    required String token,
    required PushNotificationRequest request,
    required List<int> recipientIds,
  }) async {
    if (recipientIds.isEmpty) {
      return _sendSelfNotification(token: token, request: request);
    }

    SendNotificationResult? lastResult;
    var successCount = 0;

    for (final recipientId in recipientIds) {
      final result = await _postTargetedNotification(
        token: token,
        request: request,
        recipientId: recipientId,
      );
      lastResult = result;
      successCount += result.success ? 1 : 0;
    }

    final successfulCount = recipientIds.length;
    if (successfulCount > 1) {
      return SendNotificationResult(
        success: true,
        message: 'Notification sent to $successCount users.',
        notification: lastResult?.notification,
      );
    }

    return lastResult ?? const SendNotificationResult(
      success: true,
      message: 'Notification sent successfully',
      notification: null,
    );
  }

  Future<SendNotificationResult> _postTargetedNotification({
    required String token,
    required PushNotificationRequest request,
    required int recipientId,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/$recipientId/');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': request.title,
        'message': request.message,
      }),
    );

    final decodedBody = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decodedBody is Map<String, dynamic>) {
        return SendNotificationResult.fromJson(decodedBody);
      }
      return SendNotificationResult(
        success: true,
        message: 'Notification sent to user $recipientId',
        notification: null,
      );
    }

    final errorMessage = _extractErrorMessage(decodedBody, response.statusCode);
    throw NotificationException(
      'Failed to send notification to user $recipientId: $errorMessage',
      statusCode: response.statusCode,
    );
  }

  /// Fetches notifications history if supported by the backend.
  ///
  /// When the endpoint is not available this method will propagate the 404 so
  /// callers can decide whether to surface it to the UI.
  Future<List<PushNotification>> fetchNotifications({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/notifications/');
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decodedBody = _safeDecode(response.body);

    if (response.statusCode == 200) {
      if (decodedBody is List) {
        return decodedBody
            .whereType<Map<String, dynamic>>()
            .map(PushNotification.fromJson)
            .toList();
      }
      throw NotificationException(
        'Unexpected response while parsing notifications list.',
        statusCode: response.statusCode,
      );
    }

    final errorMessage = _extractErrorMessage(decodedBody, response.statusCode);
    throw NotificationException(errorMessage, statusCode: response.statusCode);
  }

  dynamic _safeDecode(String source) {
    if (source.isEmpty) return null;
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(dynamic decodedBody, int statusCode) {
    if (decodedBody is Map<String, dynamic>) {
      final detail = decodedBody['detail'] ?? decodedBody['message'];
      if (detail != null) {
        return detail.toString();
      }
    }

    return 'Failed to send notification (status $statusCode).';
  }
}

class NotificationException implements Exception {
  final String message;
  final int? statusCode;

  NotificationException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
