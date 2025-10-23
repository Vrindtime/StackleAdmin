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
    final normalizedRecipientIds = request.normalizedRecipientIds.toSet().toList();

    if (request.recipientIds.isNotEmpty && normalizedRecipientIds.isEmpty) {
      throw NotificationException(
        'Unable to parse selected recipient IDs. Please refresh and try again.',
      );
    }

    if (request.broadcastToAll || normalizedRecipientIds.isEmpty) {
      return _sendSelfNotification(token: token, request: request);
    }

    return _sendBulkNotification(
      token: token,
      request: request,
      recipientIds: normalizedRecipientIds,
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

  Future<SendNotificationResult> _sendBulkNotification({
    required String token,
    required PushNotificationRequest request,
    required List<int> recipientIds,
  }) async {
    if (recipientIds.isEmpty) {
      return _sendSelfNotification(token: token, request: request);
    }

    final uri = Uri.parse('$baseUrl/notifications/bulk/');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_ids': recipientIds,
        'title': request.title,
        'message': request.message,
        if (request.liked != null) 'liked': request.liked,
      }),
    );

    final decodedBody = _safeDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decodedBody is Map<String, dynamic>) {
        return SendNotificationResult.fromJson(decodedBody);
      }
      return SendNotificationResult(
        success: true,
        message: 'Notification sent successfully',
        notification: null,
        created: recipientIds.length,
        requestedCount: recipientIds.length,
      );
    }

    if (_shouldFallbackToTargetedRoute(response.statusCode, decodedBody)) {
      return _sendTargetedNotifications(
        token: token,
        request: request,
        recipientIds: recipientIds,
      );
    }

    final errorMessage = _extractErrorMessage(decodedBody, response.statusCode);
    throw NotificationException(
      errorMessage,
      statusCode: response.statusCode,
    );
  }

  bool _shouldFallbackToTargetedRoute(int statusCode, dynamic decodedBody) {
    if (statusCode != 422) return false;
    final errors = <Map<String, dynamic>>[];

    if (decodedBody is List) {
      errors.addAll(decodedBody.whereType<Map<String, dynamic>>());
    } else if (decodedBody is Map<String, dynamic>) {
      final detail = decodedBody['detail'];
      if (detail is List) {
        errors.addAll(detail.whereType<Map<String, dynamic>>());
      }
    }

    for (final item in errors) {
      final type = item['type']?.toString();
      final loc = item['loc'];
      if (type == 'int_parsing' && loc is List && loc.length >= 2) {
        final locationSegments = loc.map((segment) => segment.toString()).toList();
        if (locationSegments[0] == 'path' && locationSegments[1] == 'user_id') {
          return true;
        }
      }
    }
    return false;
  }

  Future<SendNotificationResult> _sendTargetedNotifications({
    required String token,
    required PushNotificationRequest request,
    required List<int> recipientIds,
  }) async {
    SendNotificationResult? lastResult;
    var successCount = 0;
    final missingIds = <int>[];

    for (final recipientId in recipientIds) {
      try {
        final result = await _postTargetedNotification(
          token: token,
          request: request,
          recipientId: recipientId,
        );
        lastResult = result;
        if (result.success) {
          successCount += 1;
        } else {
          missingIds.add(recipientId);
        }
      } catch (_) {
        missingIds.add(recipientId);
      }
    }

    final message = successCount == recipientIds.length
        ? 'Notification sent to all selected users.'
        : 'Notification sent to $successCount of ${recipientIds.length} users.';

    return SendNotificationResult(
      success: successCount > 0,
      message: message,
      notification: lastResult?.notification,
      created: successCount,
      requestedCount: recipientIds.length,
      missingUserIds: missingIds,
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
        if (request.liked != null) 'liked': request.liked,
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
        created: 1,
        requestedCount: 1,
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
