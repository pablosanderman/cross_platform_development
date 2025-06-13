
import 'package:equatable/equatable.dart';

enum GroupRoles {
  member,
  moderator,
  administrator
}

class Person extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  late final GroupRoles? role;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.role = GroupRoles.member,
  });

  void setRole(GroupRoles role) {
    this.role = role;
  }

  @override
  // TODO: implement props
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    role,
  ];
}