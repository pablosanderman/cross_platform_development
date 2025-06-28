import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// {@template users_repository}
/// Repository for loading and managing users data.
/// Provides a single source of truth for user data across the app.
/// {@endtemplate}
class UsersRepository {
  /// {@macro users_repository}
  const UsersRepository();

  /// Load all users from the JSON data file
  Future<List<User>> loadUsers() async {
    final raw = await rootBundle.loadString('users.json');
    final data = jsonDecode(raw) as List<dynamic>;
    final users = data
        .map((u) => User.fromJson(u as Map<String, dynamic>))
        .toList();
    return users;
  }

  /// Load a specific user by ID
  Future<User?> loadUser(String userId) async {
    final users = await loadUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Load users for a specific group
  Future<List<User>> loadUsersForGroup(String groupId) async {
    final users = await loadUsers();
    return users.where((user) => user.groupIds.contains(groupId)).toList();
  }
}