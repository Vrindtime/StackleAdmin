class FeedbackModel {
  final int id;
  final int userId;
  final String subject;
  final String message;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to format the date for display
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year} - ${createdAt.hour.toString().padLeft(2, '0')}.${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour >= 12 ? 'PM' : 'AM'}';
  }
}