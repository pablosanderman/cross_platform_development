import 'package:equatable/equatable.dart';

/// {@template user}
/// Represents a user in the volcanic monitoring system
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.groupIds,
  });

  /// Unique identifier for the user
  final String id;

  /// First name of the user
  final String firstName;

  /// Last name of the user
  final String lastName;

  /// Role of the user (administrator, member, etc.)
  final String role;

  /// List of group IDs this user belongs to
  final List<String> groupIds;

  /// Gets the display name by combining first and last name
  String get displayName => '$firstName $lastName';

  /// Creates a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      groupIds: (json['groupIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'groupIds': groupIds,
    };
  }

  /// Creates a copy of this User with the given fields replaced
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? role,
    List<String>? groupIds,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  @override
  List<Object> get props => [id, firstName, lastName, role, groupIds];
}