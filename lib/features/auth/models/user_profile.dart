class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String name;
  final int? age;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
