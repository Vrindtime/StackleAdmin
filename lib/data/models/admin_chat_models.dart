// Models for admin chat APIs: client conversations and messages
class ClientInfo {
  final int id;
  final String name;
  final String? avatar;
  final String? email;

  ClientInfo({required this.id, required this.name, this.avatar, this.email});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
      avatar: json['avatar'],
      email: json['email'],
    );
  }
}

class OrgInfo {
  final int id;
  final String name;
  final String? avatar;

  OrgInfo({required this.id, required this.name, this.avatar});

  factory OrgInfo.fromJson(Map<String, dynamic> json) {
    return OrgInfo(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
      avatar: json['avatar'],
    );
  }
}

class ConversationSummary {
  final int id;
  final OrgInfo organization;
  final String? lastMessageText;
  final DateTime? lastMessageTimestamp;
  final DateTime updatedAt;
  final bool isBlocked;
  final String? blockedBy;

  ConversationSummary({
    required this.id,
    required this.organization,
    this.lastMessageText,
    this.lastMessageTimestamp,
    required this.updatedAt,
    required this.isBlocked,
    this.blockedBy,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseIso(String? s) {
      if (s == null) return null;
      try {
        return DateTime.tryParse(s)?.toLocal();
      } catch (_) {
        return null;
      }
    }

    return ConversationSummary(
      id: json['id'] ?? 0,
      organization: OrgInfo.fromJson((json['organization'] ?? {}) as Map<String, dynamic>),
      lastMessageText: json['last_message_text'] ?? json['lastMessageText'],
      lastMessageTimestamp: parseIso((json['last_message_timestamp'] ?? json['lastMessageTimestamp'])?.toString()),
      updatedAt: parseIso(json['updated_at']?.toString()) ?? DateTime.now(),
      isBlocked: json['isBlocked'] == true || json['is_blocked'] == true || json['blocked'] == true,
      blockedBy: json['blocked_by'] ?? json['blockedBy'] ?? null,
    );
  }
}

class ClientConversationsResponse {
  final ClientInfo client;
  final List<ConversationSummary> conversations;

  ClientConversationsResponse({required this.client, required this.conversations});

  factory ClientConversationsResponse.fromJson(Map<String, dynamic> json) {
    final clientJson = (json['client'] ?? {}) as Map<String, dynamic>;
    final convs = (json['conversations'] as List<dynamic>?) ?? [];
    return ClientConversationsResponse(
      client: ClientInfo.fromJson(clientJson),
      conversations: convs.whereType<Map<String, dynamic>>().map((e) => ConversationSummary.fromJson(e)).toList(),
    );
  }
}

class MessageModel {
  final int id;
  final String? text;
  final String? messageType;
  final String? fileUrl;
  final DateTime timestamp;
  final int? timestampMs;
  final int? senderUserId;
  final String? senderName;
  final String? senderType;
  final int? senderEntityId;
  final String? senderAvatar;
  final bool isDeleted;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    this.text,
    this.messageType,
    this.fileUrl,
    required this.timestamp,
    this.timestampMs,
    this.senderUserId,
    this.senderName,
    this.senderType,
    this.senderEntityId,
    this.senderAvatar,
    required this.isDeleted,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseIsoNullable(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.tryParse(v.toString())?.toLocal();
      } catch (_) {
        return null;
      }
    }

    final tsVal = json['timestamp'] ?? json['time'] ?? json['created_at'];
    final DateTime timestamp = tsVal != null
        ? (DateTime.tryParse(tsVal.toString())?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch((json['timestamp_ms'] is int) ? json['timestamp_ms'] as int : 0).toLocal())
        : DateTime.fromMillisecondsSinceEpoch((json['timestamp_ms'] is int) ? json['timestamp_ms'] as int : 0).toLocal();

    return MessageModel(
      id: json['id'] ?? 0,
      text: json['text'] ?? json['message'] ?? json['content'],
      messageType: json['message_type'] ?? json['type'],
      fileUrl: json['file_url'] ?? json['fileUrl'] ?? json['file'],
      timestamp: timestamp,
      timestampMs: json['timestamp_ms'] is int ? json['timestamp_ms'] as int : (json['timestamp_ms'] is String ? int.tryParse(json['timestamp_ms']) : null),
      senderUserId: json['sender_user_id'] is int ? json['sender_user_id'] as int : (json['senderUserId'] is int ? json['senderUserId'] as int : null),
      senderName: json['sender_name'] ?? json['senderName'],
      senderType: json['sender_type'] ?? json['senderType'],
      senderEntityId: json['sender_entity_id'] is int ? json['sender_entity_id'] as int : (json['senderEntityId'] is int ? json['senderEntityId'] as int : null),
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      isDeleted: json['is_deleted'] == true || json['isDeleted'] == true || json['deleted'] == true,
      readAt: parseIsoNullable(json['read_at'] ?? json['readAt']),
    );
  }
}
