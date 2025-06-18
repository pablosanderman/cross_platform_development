import 'package:cross_platform_development/HandleFakeAccount.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'groups_event.dart';
import 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc()
    : super(
        GroupsState(
          chosenGroup: null,
          groups: const [],
          users: const [],
        ),
      ) {
    on<ChooseGroup>(_setChosenGroup);
    on<LoadGroups>(_loadGroups);
    on<LoadUsers>(_loadUsers);
  }

  Future<void> _loadUsers(LoadUsers event, Emitter<GroupsState> emit) async {
    try {
      final users = await User.loadPersonsFromFile();
      emit(state.copyWith(users: users));
    } catch (e) {
      // Handle error appropriately
      print('Error loading users: $e');
      emit(state.copyWith(users: []));
    }
  }

  Future<void> _loadGroups(LoadGroups event, Emitter<GroupsState> emit) async {
    try {
      final groups = await Group.loadGroupsFromFile();
      emit(state.copyWith(groups: groups));
    } catch (e) {
      // Handle error appropriately
      print('Error loading groups: $e');
      emit(state.copyWith(groups: []));
    }
  }

  void _setChosenGroup(ChooseGroup event, Emitter<GroupsState> emit) {
    emit(state.copyWith(chosenGroup: event.chosenGroup));
  }

  // TODO: Delete or change
  // static final List<Group> _testGroups = [
  //   Group(name: "TestGroup1", id: , ownerId: FakeAccount().people[0].id, groupMemberIds: {
  //     FakeAccount().people[0].id: GroupRoles.administrator,
  //     FakeAccount().people[1].id: GroupRoles.member,
  //     FakeAccount().people[2].id: GroupRoles.member,
  //   }, id: "testid1"),
  //   Group(name: "TestGroup2", id: , ownerId: FakeAccount().people[1].id, groupMemberIds: {
  //     FakeAccount().people[1].id: GroupRoles.administrator,
  //     FakeAccount().people[0].id: GroupRoles.member,
  //     FakeAccount().people[2].id: GroupRoles.member,
  //   }, id: "testid2"),
  //   Group(name: "TestGroup3", id: , ownerId: FakeAccount().people[2].id, groupMemberIds: {
  //     FakeAccount().people[2].id: GroupRoles.administrator,
  //     FakeAccount().people[1].id: GroupRoles.member,
  //     FakeAccount().people[0].id: GroupRoles.member,
  //   }, id: "testid3"),
  // ];

  void createGroup(String gName) {
    final currentGroups = List<Group>.from(state.groups);
    var uuid = Uuid();
    Group group = Group(
      id: uuid.v4(),
      name: gName,
      ownerId: FakeAccount.loggedInUser!.id,
    );
    group.addMember(FakeAccount.loggedInUser!.id);
    FakeAccount.loggedInUser!.groupIds.add(group.id);
    currentGroups.add(group);

    emit(state.copyWith(groups: currentGroups));
  }

  List<Group> getGroups() {
    return state.groups;
  }
}
