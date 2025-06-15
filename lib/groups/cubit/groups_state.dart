import 'package:equatable/equatable.dart';

import '../models/models.dart';

class GroupsState extends Equatable {
  final Group? chosenGroup;
  final List<Group> groups;
  final Map<Person, GroupRoles> groupMembers;

  const GroupsState({
    required this.chosenGroup,
    required this.groups,
    required this.groupMembers
  });

  GroupsState copyWith({
    Group? chosenGroup,
    List<Group>? groups,
    Map<Person, GroupRoles>? groupMembers,
  }) {
    return GroupsState(
      chosenGroup: chosenGroup?? this.chosenGroup,
      groups: groups ?? this.groups,
      groupMembers: groupMembers ?? this.groupMembers,
    );
  }

  @override
  List<Object?> get props => [chosenGroup, groups, groupMembers];
}