class PushNotificationRequest {
  final String title;
  final String message;
  final bool broadcastToAll;
  final List<dynamic> recipientIds;
  final bool? liked;

  const PushNotificationRequest({
    required this.title,
    required this.message,
    this.broadcastToAll = false,
    this.recipientIds = const [],
    this.liked,
  });

  List<int> get normalizedRecipientIds {
    final result = <int>[];
    for (final raw in recipientIds) {
      if (raw == null) continue;
      if (raw is int) {
        result.add(raw);
        continue;
      }
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'title': title,
      'message': message,
      'broadcast': broadcastToAll,
    };

    if (!broadcastToAll) {
      payload['user_ids'] = normalizedRecipientIds;
    }

    if (liked != null) {
      payload['liked'] = liked;
    }

    return payload;
  }
}

class PushNotification {
  final int? id;
  final String title;
  final String message;
  final bool broadcast;
  final List<int> userIds;
  final DateTime? createdAt;

  const PushNotification({
    this.id,
    required this.title,
    required this.message,
    required this.broadcast,
    this.userIds = const [],
    this.createdAt,
  });

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: _parseId(json['id']),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      broadcast: json['broadcast'] == true || json['is_broadcast'] == true,
      userIds: _parseUserIds(json['user_ids'] ?? json['recipients']),
      createdAt: _parseDate(json['created_at'] ?? json['timestamp']),
    );
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static List<int> _parseUserIds(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((item) {
            if (item is int) return item;
            return int.tryParse(item.toString());
          })
          .whereType<int>()
          .toList();
    }
    final parsed = int.tryParse(value.toString());
    return parsed != null ? [parsed] : const [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class SendNotificationResult {
  final bool success;
  final String message;
  final PushNotification? notification;
  final int? created;
  final int? requestedCount;
  final List<int> missingUserIds;

  const SendNotificationResult({
    required this.success,
    required this.message,
    this.notification,
    this.created,
    this.requestedCount,
    this.missingUserIds = const [],
  });

  factory SendNotificationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
  final missingIds = PushNotification._parseUserIds(json['missing_user_ids']);
    return SendNotificationResult(
      success: json['success'] == true || json['status'] == 'success',
      message: (json['message'] ?? json['detail'] ?? '').toString(),
      notification: data is Map<String, dynamic>
          ? PushNotification.fromJson(data)
          : (json.containsKey('notification') && json['notification'] is Map<String, dynamic>
              ? PushNotification.fromJson(json['notification'])
              : null),
      created: _parseCount(json['created']),
      requestedCount: _parseCount(json['requested_count'] ?? json['requestedCount']),
      missingUserIds: missingIds,
    );
  }

  static int? _parseCount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
