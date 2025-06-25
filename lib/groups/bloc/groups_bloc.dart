import 'package:cross_platform_development/handle_fake_account.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'groups_event.dart';
import 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc()
    : super(GroupsState(chosenGroup: null, groups: const [], users: const [])) {
    on<ChooseGroup>(_setChosenGroup);
    on<LoadGroups>(_loadGroups);
    on<LoadUsers>(_loadUsers);
    on<ChangeGroupMemberRole>(_handleGroupMemberRoleChange);
    on<RemoveMember>(_handleRemoveMember);
    on<DeleteGroup>(_handleDeleteGroup);
    on<CreateGroup>(_handleCreateGroup);
    on<AddMember>(_handleAddMemberToGroup);
  }

  void _handleDeleteGroup(DeleteGroup event, Emitter<GroupsState> emit) {
    final updatedGroups = state.groups
        .where((g) => g.id != event.groupId)
        .toList();

    emit(state.copyWith(groups: updatedGroups));
  }

  void _handleRemoveMember(RemoveMember event, Emitter<GroupsState> emit) {
    final updatedGroups = state.groups.map((group) {
      if (group.id == event.groupId) {
        return _removeUserFromGroupMembers(group, event.user.id);
      }
      return group;
    }).toList();

    final updatedUsers = state.users.map((currentUser) {
      if (currentUser.id == event.user.id) {
        return _removeGroupFromUser(currentUser, event.groupId);
      }
      return currentUser;
    }).toList();

    emit(
      state.copyWith(
        groups: updatedGroups,
        users: updatedUsers,
        chosenGroup: _getUpdatedChosenGroup(updatedGroups, event.groupId),
      ),
    );
    Group.saveGroupsToFile(updatedGroups);
  }

  void _handleGroupMemberRoleChange(
    ChangeGroupMemberRole event,
    Emitter<GroupsState> emit,
  ) {
    final updatedGroups = state.groups.map((g) {
      if (g.id == event.group.id) {
        final newGroup = Group(
          id: g.id,
          name: g.name,
          ownerId: g.ownerId,
          groupMemberIds: Map<String, GroupRoles>.from(g.groupMemberIds),
        );
        newGroup.changeRole(event.userId, event.newRole);
        return newGroup;
      }
      return g;
    }).toList();

    emit(
      state.copyWith(
        groups: updatedGroups,
        chosenGroup: _getUpdatedChosenGroup(updatedGroups, event.group.id),
      ),
    );
    DataManager.saveAllData(getUsers(), getGroups());
  }

  Future<void> _loadUsers(LoadUsers event, Emitter<GroupsState> emit) async {
    try {
      final users = await User.loadUsersFromFile();
      emit(state.copyWith(users: users));

      // Set the logged-in user after users are loaded
      if (users.isNotEmpty && FakeAccount.loggedInUser == null) {
        final loggedInUser = users.firstWhere(
          (p) => p.firstName == "Andrew",
          orElse: () =>
              users.first, // Fallback to first user if Andrew not found
        );
        FakeAccount.loggedInUser = loggedInUser;
      }
    } catch (e) {
      // Handle error appropriately
      emit(state.copyWith(users: []));
    }
  }

  Future<void> _loadGroups(LoadGroups event, Emitter<GroupsState> emit) async {
    try {
      final groups = await Group.loadGroupsFromFile();
      emit(state.copyWith(groups: groups));
    } catch (e) {
      // Handle error appropriately
      emit(state.copyWith(groups: []));
    }
  }

  void _setChosenGroup(ChooseGroup event, Emitter<GroupsState> emit) {
    emit(state.copyWith(chosenGroup: event.chosenGroup));
  }

  Future<void> _handleCreateGroup(
    CreateGroup event,
    Emitter<GroupsState> emit,
  ) async {
    // If no logged in user and no users loaded, try to load users first
    if (FakeAccount.loggedInUser == null && state.users.isEmpty) {
      await _loadUsers(LoadUsers(), emit);
    }

    if (FakeAccount.loggedInUser == null) {
      return;
    }

    var uuid = Uuid();
    Group group = Group(
      id: uuid.v4(),
      name: event.groupName,
      ownerId: FakeAccount.loggedInUser!.id,
    );
    group.addMember(FakeAccount.loggedInUser!.id);
    FakeAccount.loggedInUser!.groupIds.add(group.id);

    final updatedGroups = List<Group>.from(state.groups)..add(group);

    emit(state.copyWith(groups: updatedGroups));
  }

  List<Group> getGroups() {
    return state.groups;
  }

  List<User> getUsers() {
    return state.users;
  }

  void _handleAddMemberToGroup(AddMember event, Emitter<GroupsState> emit) {
    final updatedGroups = state.groups.map((group) {
      if (group == event.chosenGroup) {
        final newGroup = Group(
          id: group.id,
          name: group.name,
          ownerId: group.ownerId,
          groupMemberIds: Map<String, GroupRoles>.from(group.groupMemberIds),
        );
        newGroup.addMember(event.chosenUser.id, role: event.role);
        return newGroup;
      }
      return group;
    }).toList();

    final updatedUsers = state.users.map((user) {
      if (user == event.chosenUser) {
        final newUser = User(
          id: user.id,
          firstName: user.firstName,
          lastName: user.lastName,
          role: user.role,
          groupIds: List<String>.from(user.groupIds),
        );
        newUser.addGroup(event.chosenGroup.id);
        return newUser;
      }
      return user;
    }).toList();

    final updatedChosenGroup = updatedGroups.firstWhere(
      (g) => g.id == event.chosenGroup.id,
    );
    emit(
      state.copyWith(
        groups: updatedGroups,
        users: updatedUsers,
        chosenGroup: updatedChosenGroup,
      ),
    );
  }

  Group _getUpdatedChosenGroup(List<Group> updatedGroups, String groupId) {
    return updatedGroups.firstWhere((g) => g.id == groupId);
  }

  Group _removeUserFromGroupMembers(Group group, String userId) {
    final newGroupMemberIds = Map<String, GroupRoles>.from(group.groupMemberIds)
      ..remove(userId);
    return Group(
      name: group.name,
      id: group.id,
      ownerId: group.ownerId,
      groupMemberIds: newGroupMemberIds,
    );
  }

  User _removeGroupFromUser(User user, String groupId) {
    final newGroupIds = List<String>.from(user.groupIds)..remove(groupId);
    return User(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      groupIds: newGroupIds,
    );
  }
}
