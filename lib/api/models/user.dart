class User {
  final int id;
  final String? email;
  final bool isActive;
  final Role role;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  User({
    required this.id,
    required this.email,
    required this.isActive,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email']?.toString(),
      isActive: json['is_active'] ?? true,
      accessToken: json['access_token']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
      tokenType: json['token_type']?.toString(),
      role: json["role"] == "editor" ? Role.editor : Role.user,
    );
  }
}

enum Role { editor, user }
