class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final String phone;
  final String deviceId;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    required this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      deviceId: json['device_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'device_id': deviceId,
    };
  }
}