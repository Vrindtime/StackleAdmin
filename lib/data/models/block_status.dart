class BlockedUserStatus {
  final int userId;
  final bool isBlocked;
  final DateTime? blockedAt;
  BlockedUserStatus({required this.userId, required this.isBlocked, this.blockedAt});
  factory BlockedUserStatus.fromJson(Map<String, dynamic> json) => BlockedUserStatus(
        userId: json['user_id'] ?? 0,
        isBlocked: json['is_blocked'] ?? false,
        blockedAt: json['blocked_at'] != null && json['blocked_at'] != ''
            ? DateTime.tryParse(json['blocked_at'])
            : null,
      );
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'is_blocked': isBlocked,
        'blocked_at': blockedAt?.toIso8601String(),
      };
}

class BlockedOrganisationStatus {
  final int organisationId;
  final bool isBlocked;
  final DateTime? blockedAt;
  BlockedOrganisationStatus({required this.organisationId, required this.isBlocked, this.blockedAt});
  factory BlockedOrganisationStatus.fromJson(Map<String, dynamic> json) => BlockedOrganisationStatus(
        organisationId: json['organisation_id'] ?? 0,
        isBlocked: json['is_blocked'] ?? false,
        blockedAt: json['blocked_at'] != null && json['blocked_at'] != ''
            ? DateTime.tryParse(json['blocked_at'])
            : null,
      );
  Map<String, dynamic> toJson() => {
        'organisation_id': organisationId,
        'is_blocked': isBlocked,
        'blocked_at': blockedAt?.toIso8601String(),
      };
}

class BlockedUserListItem {
  final int userId;
  final DateTime blockedAt;
  BlockedUserListItem({required this.userId, required this.blockedAt});
  factory BlockedUserListItem.fromJson(Map<String, dynamic> json) => BlockedUserListItem(
        userId: json['user_id'] ?? 0,
        blockedAt: DateTime.tryParse(json['blocked_at'] ?? '') ?? DateTime.now(),
      );
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'blocked_at': blockedAt.toIso8601String(),
      };
}

class BlockedOrganisationListItem {
  final int organisationId;
  final DateTime blockedAt;
  BlockedOrganisationListItem({required this.organisationId, required this.blockedAt});
  factory BlockedOrganisationListItem.fromJson(Map<String, dynamic> json) => BlockedOrganisationListItem(
        organisationId: json['organisation_id'] ?? 0,
        blockedAt: DateTime.tryParse(json['blocked_at'] ?? '') ?? DateTime.now(),
      );
  Map<String, dynamic> toJson() => {
        'organisation_id': organisationId,
        'blocked_at': blockedAt.toIso8601String(),
      };
}
