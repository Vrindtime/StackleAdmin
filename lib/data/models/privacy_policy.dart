class PrivacyPolicy {
  final int? id;
  final String text;
  final DateTime? updatedAt;

  const PrivacyPolicy({
    this.id,
    required this.text,
    this.updatedAt,
  });

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicy(
      id: _parseId(json['id']),
      text: (json['text'] ?? '').toString(),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'text': text,
        'updated_at': updatedAt?.toIso8601String(),
      };

  PrivacyPolicy copyWith({
    int? id,
    String? text,
    DateTime? updatedAt,
  }) {
    return PrivacyPolicy(
      id: id ?? this.id,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String? get formattedUpdatedAt {
    if (updatedAt == null) return null;
    final local = updatedAt!.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final date = '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
    final time = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    return '$date $time';
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
  }
}
