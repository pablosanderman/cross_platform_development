import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

// Right now it is the same yes, but they should be distinguished for the future.
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
  final String ownerId; // Changed from Person owner to String ownerId
  final Map<String, GroupRoles> groupMemberIds; // Changed from Map<Person, GroupRoles> to Map<String, GroupRoles>

  void addMember(String personId, {GroupRoles role = GroupRoles.member}) {
    if (personId == ownerId) {
      groupMemberIds[personId] = GroupRoles.administrator;
      return;
    }
    groupMemberIds[personId] = role;
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

  // Get Groups.json file path
  static String get _groupsFilePath => path.join(Directory.current.path, 'Groups.json');

  // Save single group to Groups.json
  static Future<void> saveGroupToFile(Group group) async {
    try {
      final file = File(_groupsFilePath);
      final jsonString = jsonEncode(group.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save group to file: $e');
    }
  }

  // Load single group from Groups.json - no personLookup needed!
  static Future<Group> loadGroupFromFile() async {
    try {
      final file = File(_groupsFilePath);
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
      final file = File(_groupsFilePath);
      final jsonList = groups.map((group) => group.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save groups to file: $e');
    }
  }

  // Load multiple groups from Groups.json - no personLookup needed!
  static Future<List<Group>> loadGroupsFromFile() async {
    try {
      final file = File(_groupsFilePath);
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return [];
      }
      final jsonList = List<dynamic>.from(jsonDecode(jsonString));
      return jsonList.map((json) => Group.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load groups from file: $e');
    }
  }

  // Add single group to Groups.json
  static Future<void> addGroupToFile(Group group) async {
    try {
      List<Group> existingGroups = await loadGroupsFromFile();
      
      // Add new group (check for duplicates by ID)
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
  final List<String> groupIds; // Changed from List<Group> to List<String>

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

  // JSON serialization - now much simpler!
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'groupIds': groupIds,
    };
  }

  // JSON deserialization - much simpler!
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

  // Get Users.json file path
  static String get _usersFilePath => path.join(Directory.current.path, 'Users.json');

  // Save single person to Users.json
  static Future<void> savePersonToFile(User person) async {
    try {
      final file = File(_usersFilePath);
      final jsonString = jsonEncode(person.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save person to file: $e');
    }
  }

  // Load single person from Users.json
  static Future<User> loadPersonFromFile() async {
    try {
      final file = File(_usersFilePath);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      return User.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load person from file: $e');
    }
  }

  // Save multiple persons to Users.json
  static Future<void> savePersonsToFile(List<User> persons) async {
    try {
      final file = File(_usersFilePath);
      final jsonList = persons.map((person) => person.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save persons to file: $e');
    }
  }

  // Load multiple persons from Users.json
  static Future<List<User>> loadPersonsFromFile() async {
    try {
      final file = File(_usersFilePath);
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return [];
      }
      final jsonList = List<dynamic>.from(jsonDecode(jsonString));
      return jsonList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load persons from file: $e');
    }
  }

  // Add single person to Users.json
  static Future<void> addPersonToFile(User person) async {
    try {
      List<User> existingPersons = await loadPersonsFromFile();
      
      // Add new person (check for duplicates by ID)
      if (!existingPersons.any((p) => p.id == person.id)) {
        existingPersons.add(person);
        await savePersonsToFile(existingPersons);
      }
    } catch (e) {
      throw Exception('Failed to add person to file: $e');
    }
  }
}

// Helper class for managing data persistence and lookups
class DataManager {
  // Load all data
  static Future<Map<String, dynamic>> loadAllData() async {
    try {
      final persons = await User.loadPersonsFromFile();
      final groups = await Group.loadGroupsFromFile();

      // Create lookup maps for easy access
      final personLookup = {for (var person in persons) person.id: person};
      final groupLookup = {for (var group in groups) group.id: group};

      return {
        'persons': persons,
        'groups': groups,
        'personLookup': personLookup,
        'groupLookup': groupLookup,
      };
    } catch (e) {
      throw Exception('Failed to load all data: $e');
    }
  }

  // Save all data
  static Future<void> saveAllData(List<User> persons, List<Group> groups) async {
    try {
      await User.savePersonsToFile(persons);
      await Group.saveGroupsToFile(groups);
    } catch (e) {
      throw Exception('Failed to save all data: $e');
    }
  }

  // Helper method to get a person by ID from a list
  static User? getPersonById(List<User> persons, String personId) {
    try {
      return persons.firstWhere((person) => person.id == personId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get a group by ID from a list
  static Group? getGroupById(List<Group> groups, String groupId) {
    try {
      return groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return null;
    }
  }

  // Get file paths for reference
  static String get groupsFilePath => path.join(Directory.current.path, 'Groups.json');
  static String get usersFilePath => path.join(Directory.current.path, 'Users.json');
}