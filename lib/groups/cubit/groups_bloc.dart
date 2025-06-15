import 'package:cross_platform_development/HandleFakeAccount.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'groups_event.dart';
import 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState>{
  GroupsBloc()
    : super(GroupsState(
      chosenGroup: null,
      groups: _testGroups,
      groupMembers: const {}
    )) {
  on<ChooseGroup>(_setChosenGroup);
  }

  void _setChosenGroup(
    ChooseGroup event,
    Emitter<GroupsState> emit,
    ) {
    emit(state.copyWith(chosenGroup: event.chosenGroup));
  }

  static final List<Group> _testGroups = [
    Group(name: "TestGroup1", owner: FakeAccount().people[0], groupMembers: {
      FakeAccount().people[0]: GroupRoles.administrator,
      FakeAccount().people[1]: GroupRoles.member,
      FakeAccount().people[2]: GroupRoles.member,
    }, id: "testid1"),
    Group(name: "TestGroup2", owner: FakeAccount().people[1], groupMembers: {
      FakeAccount().people[1]: GroupRoles.administrator,
      FakeAccount().people[0]: GroupRoles.member,
      FakeAccount().people[2]: GroupRoles.member,
    }, id: "testid2"),
    Group(name: "TestGroup3",owner: FakeAccount().people[2], groupMembers: {
      FakeAccount().people[2]: GroupRoles.administrator,
      FakeAccount().people[1]: GroupRoles.member,
      FakeAccount().people[0]: GroupRoles.member,
    }, id: "testid3"),
  ];



  void createGroup(String gName) {
    final currentGroups = List<Group>.from(state.groups);
    var uuid = Uuid();
    Group group = Group(
        name: gName,
        owner: FakeAccount().loggedInUser,
        id: uuid.v4(),
    );
    // group.addMember(FakeAccount().loggedInUser); TODO: change or delete

    currentGroups.add(group);
    emit(state.copyWith(groups: currentGroups));
  }

  List<Group> getGroups() {
    return state.groups;
  }
}