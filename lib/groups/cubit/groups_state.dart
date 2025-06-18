import 'package:equatable/equatable.dart';

import '../models/models.dart';

class GroupsState extends Equatable {
  final Group? chosenGroup;
  final List<Group> groups;
  final List<User> users;

  const GroupsState({
    required this.chosenGroup,
    required this.groups,
    required this.users,
  });

  GroupsState copyWith({
    Group? chosenGroup,
    List<Group>? groups,
    List<User>? users,
    Map<User, GroupRoles>? groupMembers,
  }) {
    return GroupsState(
      chosenGroup: chosenGroup?? this.chosenGroup,
      groups: groups ?? this.groups,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [chosenGroup, groups, users];
}