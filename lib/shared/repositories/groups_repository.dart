import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// {@template groups_repository}
/// Repository for loading and managing groups data.
/// Provides a single source of truth for group data across the app.
/// {@endtemplate}
class GroupsRepository {
  /// {@macro groups_repository}
  const GroupsRepository();

  /// Load all groups from the JSON data file
  Future<List<Group>> loadGroups() async {
    final raw = await rootBundle.loadString('groups.json');
    final data = jsonDecode(raw) as List<dynamic>;
    final groups = data
        .map((g) => Group.fromJson(g as Map<String, dynamic>))
        .toList();
    return groups;
  }

  /// Load a specific group by ID
  Future<Group?> loadGroup(String groupId) async {
    final groups = await loadGroups();
    try {
      return groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Load groups for a list of group IDs
  Future<List<Group>> loadGroupsForIds(List<String> groupIds) async {
    final allGroups = await loadGroups();
    return allGroups.where((group) => groupIds.contains(group.id)).toList();
  }
}