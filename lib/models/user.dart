/// Modelo de usuario
class User {
  final int id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }
}

