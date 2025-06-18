
import '../models/models.dart';

abstract class GroupsEvent {
  GroupsEvent();
}

class ChooseGroup extends GroupsEvent {
  final Group chosenGroup;
  ChooseGroup(this.chosenGroup) : super();
}

class LoadGroups extends GroupsEvent {}
class SaveGroups extends GroupsEvent {}
class LoadUsers extends GroupsEvent {}
class DeleteGroup extends GroupsEvent {}
class RemoveMember extends GroupsEvent {}