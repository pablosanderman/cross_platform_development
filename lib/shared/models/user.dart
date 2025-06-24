import 'package:equatable/equatable.dart';

/// {@template user}
/// Represents a user in the volcanic monitoring system
/// {@endtemplate}
class User extends Equatable {
  /// {@macro user}
  const User({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.groups,
  });

  /// Unique identifier for the user
  final String id;

  /// Display name for the user
  final String displayName;

  /// Avatar/profile image path for the user
  final String avatar;

  /// List of group IDs this user belongs to
  final List<String> groups;

  /// Creates a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String,
      groups: (json['groups'] as List<dynamic>).cast<String>(),
    );
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatar': avatar,
      'groups': groups,
    };
  }

  /// Creates a copy of this User with the given fields replaced
  User copyWith({
    String? id,
    String? displayName,
    String? avatar,
    List<String>? groups,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      groups: groups ?? this.groups,
    );
  }

  @override
  List<Object> get props => [id, displayName, avatar, groups];
}