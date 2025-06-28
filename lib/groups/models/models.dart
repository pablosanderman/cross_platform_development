import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum GroupRoles { member, moderator, administrator, owner }

enum SystemRoles { member, moderator, administrator }

class Group {
  Group({
    required this.name,
    required this.id,
    required this.ownerId,
    Map<String, GroupRoles>? groupMemberIds,
  }) : groupMemberIds = groupMemberIds ?? {};

  final String name;
  final String id;
  final String ownerId;
  final Map<String, GroupRoles> groupMemberIds;

  void addMember(String userID, {GroupRoles role = GroupRoles.member}) {
    if (userID == ownerId) {
      groupMemberIds[userID] = GroupRoles.owner;
      return;
    }
    groupMemberIds[userID] = role;
  }

  static List<User> getGroupMembers(
    Iterable<String> groupMemberIds,
    List<User> users,
  ) {
    return users.where((p) => groupMemberIds.contains(p.id)).toList();
  }

  static List<User> getNonGroupMembers(
    Iterable<String> groupMemberIds,
    List<User> users,
  ) {
    return users.where((p) => !groupMemberIds.contains(p.id)).toList();
  }

  void removeMember(String personId) {
    groupMemberIds.remove(personId);
  }

  void changeRole(String personId, GroupRoles newRole) {
    if (!groupMemberIds.containsKey(personId)) return;
    groupMemberIds[personId] = newRole;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'ownerId': ownerId,
      'groupMemberIds': groupMemberIds.map(
        (personId, role) => MapEntry(personId, role.name),
      ),
    };
  }

  // JSON deserialization
  factory Group.fromJson(Map<String, dynamic> json) {
    final groupMemberIds = <String, GroupRoles>{};

    if (json['groupMemberIds'] != null) {
      final membersMap = Map<String, String>.from(json['groupMemberIds']);
      for (final entry in membersMap.entries) {
        final role = GroupRoles.values.firstWhere(
          (r) => r.name == entry.value,
          orElse: () => GroupRoles.member,
        );
        groupMemberIds[entry.key] = role;
      }
    }

    return Group(
      name: json['name'],
      id: json['id'],
      ownerId: json['ownerId'],
      groupMemberIds: groupMemberIds,
    );
  }

  // Get writable path for groups.json in app documents directory
  static Future<String> get _groupsFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'groups.json');
  }

  // Save single group to Groups.json
  static Future<void> saveGroupToFile(Group group) async {
    try {
      final filePath = await _groupsFilePath;
      final file = File(filePath);
      final jsonString = jsonEncode(group.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save group to file: $e');
    }
  }

  // Load single group from Groups.json - no personLookup needed!
  static Future<Group> loadGroupFromFile() async {
    try {
      final filePath = await _groupsFilePath;
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      return Group.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load group from file: $e');
    }
  }

  // Save multiple groups to Groups.json
  static Future<void> saveGroupsToFile(List<Group> groups) async {
    try {
      final filePath = await _groupsFilePath;
      final file = File(filePath);
      final jsonList = groups.map((group) => group.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save groups to file: $e');
    }
  }

  // Load multiple groups (hybrid: writable file first, then assets)
  static Future<List<Group>> loadGroupsFromFile() async {
    try {
      // First try to load from writable location
      final filePath = await _groupsFilePath;
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonList = List<dynamic>.from(jsonDecode(jsonString));
          return jsonList.map((json) => Group.fromJson(json)).toList();
        }
      }

      // Fall back to loading from assets
      final jsonString = await rootBundle.loadString('groups.json');

      if (jsonString.isEmpty) {
        return [];
      }

      final jsonList = List<dynamic>.from(jsonDecode(jsonString));
      return jsonList.map((json) => Group.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }


  // Add single group to Groups.json
  static Future<void> addGroupToFile(Group group) async {
    try {
      List<Group> existingGroups = await loadGroupsFromFile();

      if (!existingGroups.any((g) => g.id == group.id)) {
        existingGroups.add(group);
        await saveGroupsToFile(existingGroups);
      }
    } catch (e) {
      throw Exception('Failed to add group to file: $e');
    }
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final SystemRoles role;
  final List<String> groupIds;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.role = SystemRoles.member,
    List<String>? groupIds,
  }) : groupIds = groupIds ?? [];

  void addGroup(String groupId) {
    if (!groupIds.contains(groupId)) {
      groupIds.add(groupId);
    }
  }

  void removeGroup(String groupId) {
    groupIds.remove(groupId);
  }

  User setRole(SystemRoles newRole) {
    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      role: newRole,
      groupIds: List.from(groupIds),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'groupIds': groupIds,
    };
  }

  // JSON deserialization
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: SystemRoles.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => SystemRoles.member,
      ),
      groupIds: List<String>.from(json['groupIds'] ?? []),
    );
  }

  // Get writable path for users.json in app documents directory
  static Future<String> get _usersFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'users.json');
  }

  // Save single person to Users.json
  static Future<void> savePersonToFile(User person) async {
    try {
      final filePath = await _usersFilePath;
      final file = File(filePath);
      final jsonString = jsonEncode(person.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save person to file: $e');
    }
  }

  // Load single person from Users.json
  static Future<User> loadPersonFromFile() async {
    try {
      final filePath = await _usersFilePath;
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load person from file: $e');
    }
  }

  // Save multiple users to Users.json
  static Future<void> saveUsersToFile(List<User> users) async {
    try {
      final filePath = await _usersFilePath;
      final file = File(filePath);
      final jsonList = users.map((person) => person.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save users to file: $e');
    }
  }

  // Load multiple users (hybrid: writable file first, then assets)
  static Future<List<User>> loadUsersFromFile() async {
    try {
      // First try to load from writable location
      final filePath = await _usersFilePath;
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonList = List<dynamic>.from(jsonDecode(jsonString));
          return jsonList.map((json) => User.fromJson(json)).toList();
        }
      }

      // Fall back to loading from assets
      final jsonString = await rootBundle.loadString('users.json');

      if (jsonString.isEmpty) {
        return [];
      }

      final jsonList = List<dynamic>.from(jsonDecode(jsonString));
      return jsonList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }


  // Add single person to Users.json
  static Future<void> addUserToFile(User person) async {
    try {
      List<User> existingusers = await loadUsersFromFile();

      // Add new person (check for duplicates by ID)
      if (!existingusers.any((p) => p.id == person.id)) {
        existingusers.add(person);
        await saveUsersToFile(existingusers);
      }
    } catch (e) {
      throw Exception('Failed to add person to file: $e');
    }
  }
}

class DataManager {
  static Future<void> saveAllData(List<User> users, List<Group> groups) async {
    try {
      await User.saveUsersToFile(users);
      await Group.saveGroupsToFile(groups);
    } catch (e) {
      throw Exception('Failed to save all data: $e');
    }
  }

  static User? getPersonById(List<User> users, String personId) {
    try {
      return users.firstWhere((person) => person.id == personId);
    } catch (e) {
      return null;
    }
  }

  static Group? getGroupById(List<Group> groups, String groupId) {
    try {
      return groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  static Future<String> get groupsFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'groups.json');
  }

  static Future<String> get usersFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'users.json');
  }
}
