enum UserRole {
  guest,
  user,
  editor,
  admin;

  bool get isAdmin => this == UserRole.admin;
  bool get isEditor => this == UserRole.editor || this == UserRole.admin;
  bool get isUser => this != UserRole.guest;

  static UserRole fromString(String? role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.guest,
    );
  }
}
