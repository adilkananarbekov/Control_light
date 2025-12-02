import 'package:flutter/material.dart';

import '../models/user_account.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _users.add(
      UserAccount(
        id: 'admin',
        name: 'System Admin',
        email: 'admin@local.dev',
        password: 'admin123',
        role: UserRole.admin,
        access: {for (final id in blockTemplates) id: true},
        createdAt: DateTime.now(),
      ),
    );
  }

  final List<UserAccount> _users = [];
  UserAccount? currentUser;

  List<UserAccount> get users => List.unmodifiable(_users);
  List<String> get blockTemplates => ['block-1', 'block-2', 'block-3'];
  bool get isAdmin => currentUser?.role == UserRole.admin;

  bool login(String email, String password) {
    final user = _users.firstWhere(
      (u) =>
          u.email.toLowerCase() == email.toLowerCase() &&
          u.password == password,
      orElse: () => UserAccount(
        id: 'none',
        name: '',
        email: '',
        password: '',
        role: UserRole.operator,
        access: const {},
        createdAt: DateTime.now(),
      ),
    );
    if (user.id == 'none') return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  String? register({
    required String name,
    required String email,
    required String password,
    Map<String, bool>? accessOverride,
  }) {
    final exists = _users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) return 'Email already exists locally';
    final user = UserAccount(
      id: 'user-${_users.length + 1}',
      name: name,
      email: email,
      password: password,
      role: UserRole.operator,
      access: accessOverride ?? {for (final id in blockTemplates) id: false},
      createdAt: DateTime.now(),
    );
    _users.add(user);
    notifyListeners();
    return null;
  }

  void updateUser(String userId, {UserRole? role, Map<String, bool>? access}) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) return;
    _users[idx] = _users[idx].copyWith(role: role, access: access);
    if (currentUser?.id == userId) currentUser = _users[idx];
    notifyListeners();
  }

  void updateUserAccess({
    required String userId,
    required String blockId,
    required bool allowed,
  }) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) return;
    final access = Map<String, bool>.from(_users[idx].access);
    access[blockId] = allowed;
    _users[idx] = _users[idx].copyWith(access: access);
    if (currentUser?.id == userId) currentUser = _users[idx];
    notifyListeners();
  }

  void deleteUser(String userId) {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  bool canControlBlock(String blockId) {
    if (currentUser == null) return false;
    if (currentUser!.role == UserRole.admin) return true;
    return currentUser!.access[blockId] ?? false;
  }
}
