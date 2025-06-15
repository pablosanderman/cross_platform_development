import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';


// Right now it is the same yes, but they should be distinguished for the future.
enum GroupRoles {
  member,
  moderator,
  administrator
}

enum SystemRoles {
  member,
  moderator,
  administrator
}

class Group {
  Group({
    required this.name,
    required this.id,
    required this.owner,
    Map<Person, GroupRoles>? groupMembers,
  }) : groupMembers = groupMembers ?? {};

  final String name;
  final String id;
  final Person owner;
  final Map<Person, GroupRoles> groupMembers;

  void addMember(Person person) {
    person.addGroup(this);
    groupMembers[person] = GroupRoles.member;
  }

  void removeMember(Person personToRemove) {
    groupMembers.removeWhere((person, role) => person.id == personToRemove.id);
  }

  void changeRole(Person person, GroupRoles newRole) {
    if(!groupMembers.containsKey(person)) return;
    groupMembers[person] = newRole;
  }
}

class Person {
  final String id;
  final String firstName;
  final String lastName;
  final SystemRoles role;
  final List<Group> groups;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.role = SystemRoles.member,
    List<Group>? groups,
  }) : groups = groups ?? [];

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'groups': groups.map((group) => group.id).toList(),
    };
  }

  // JSON deserialization
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: SystemRoles.values.firstWhere(
            (role) => role.name == json['role'],
        orElse: () => SystemRoles.member,
      ),
    );
  }

  // Save SINGLE user to users file
  Future<void> saveToUsersFile() async {
    try {
      final users = await loadAllUsersFromFile();

      // Update existing user or add new one
      final existingIndex = users.indexWhere((user) => user.id == id);
      if (existingIndex != -1) {
        users[existingIndex] = this;
      } else {
        users.add(this);
      }

      await _saveUsersListToFile(users);
    } catch (e) {
      print('Error saving user to file: $e');
      rethrow;
    }
  }

  // Load ALL users from file
  static Future<List<Person>> loadAllUsersFromFile() async {
    try {
      final file = await _getUsersFile();

      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Person.fromJson(json)).toList();
    } catch (e) {
      print('Error loading users from file: $e');
      return [];
    }
  }

  // helper to save users list to file
  static Future<void> _saveUsersListToFile(List<Person> users) async {
    try {
      final file = await _getUsersFile();
      final jsonString = json.encode(users.map((user) => user.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error writing users to file: $e');
      rethrow;
    }
  }

  // helper to get users file
  static Future<File> _getUsersFile() async {
    return File(await rootBundle.loadString('users.json'));
  }

  void addGroup(Group group) {
    if (!groups.any((g) => g.id == group.id)) {
      groups.add(group);
    }
  }

  Person setRole(Person person, SystemRoles newRole) {
    return Person(
      id: person.id,
      firstName: person.firstName,
      lastName: person.lastName,
      role: newRole,
      groups: List.from(person.groups),
    );
  }
}
