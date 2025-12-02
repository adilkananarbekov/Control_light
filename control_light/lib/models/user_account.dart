enum UserRole { admin, operator }

class UserAccount {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final Map<String, bool> access;
  final DateTime createdAt;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.access,
    required this.createdAt,
  });

  UserAccount copyWith({
    String? name,
    String? email,
    String? password,
    UserRole? role,
    Map<String, bool>? access,
  }) {
    return UserAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      access: access ?? this.access,
      createdAt: createdAt,
    );
  }
}
