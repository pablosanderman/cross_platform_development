
import '../models/models.dart';

abstract class GroupsEvent {
  GroupsEvent();
}

class ChooseGroup extends GroupsEvent {
  final Group chosenGroup;
  ChooseGroup(this.chosenGroup) : super();
}