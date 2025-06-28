
import '../models/models.dart';

abstract class GroupsEvent {
  GroupsEvent();
}
class LoadGroups extends GroupsEvent {}
class SaveGroups extends GroupsEvent {}
class LoadUsers extends GroupsEvent {}

class AddMember extends GroupsEvent {
  final Group chosenGroup;
  final User chosenUser;
  final GroupRoles role = GroupRoles.member;
  AddMember(this.chosenGroup, this.chosenUser) : super();
}

class CreateGroup extends GroupsEvent {
  final String groupName;
  CreateGroup(this.groupName) : super();
}

class DeleteGroup extends GroupsEvent {
  final String groupId;
  DeleteGroup(this.groupId) : super();
}
class RemoveMember extends GroupsEvent {
  final String groupId;
  final User user;
  RemoveMember(this.groupId, this.user) : super();
}

class ChooseGroup extends GroupsEvent {
  final Group? chosenGroup;
  ChooseGroup(this.chosenGroup) : super();
}

class ChangeGroupMemberRole extends GroupsEvent {
  final Group group;
  final String userId;
  final GroupRoles newRole;

  ChangeGroupMemberRole({required this.group, required this.userId, required this.newRole});
}



