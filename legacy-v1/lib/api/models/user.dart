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
      id: json['id'],
      email: json['email'],
      isActive: json['is_active'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      role: json["role"] == "editor" ? Role.editor : Role.user,
    );
  }
}

enum Role { editor, user }
