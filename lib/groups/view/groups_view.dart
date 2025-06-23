import 'dart:collection';

import 'package:cross_platform_development/search/view/user_search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../handle_fake_account.dart';
import '../bloc/groups_bloc.dart';
import '../bloc/groups_event.dart';
import '../bloc/groups_state.dart';
import '../models/models.dart';

const backgroundStartColor = Color.fromARGB(100, 120, 70, 1);

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(flex: 1, child: LeftSide()),
          Expanded(flex: 3, child: RightSide()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<GroupsBloc>().add(LoadGroups());
    context.read<GroupsBloc>().add(LoadUsers());

    // TODO: Testing purposes
    // context.read<GroupsBloc>().createGroup("test1");
    // context.read<GroupsBloc>().createGroup("test2");
    // context.read<GroupsBloc>().createGroup("test3");
  }
}

class LeftSide extends StatelessWidget {
  LeftSide({super.key});

  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: backgroundStartColor,
            child: BlocBuilder<GroupsBloc, GroupsState>(
              builder: (context, groupState) {
                return ListView(
                  children: groupState.groups
                      .where(
                        (group) =>
                            FakeAccount.loggedInUser != null &&
                            group.groupMemberIds.keys.contains(
                              FakeAccount.loggedInUser?.id,
                            ),
                      )
                      .map((group) {
                        return Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(group.name),
                                onTap: () {
                                  context.read<GroupsBloc>().add(
                                    ChooseGroup(group),
                                  );
                                },
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () {
                                    if (FakeAccount.loggedInUser != null) {
                                      context.read<GroupsBloc>().add(
                                        RemoveMember(
                                          group.id,
                                          FakeAccount.loggedInUser!,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const Text("Leave"),
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    context.read<GroupsBloc>().add(
                                      DeleteGroup(group.id),
                                    );
                                  },
                                ),
                                const Text("Delete"),
                              ],
                            ),
                          ],
                        );
                      })
                      .toList(),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton.extended(
              label: Text("Create Group"),
              icon: Icon(Icons.add),
              onPressed: () {
                _displayTextInputDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Group name'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "group name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                _textFieldController.clear();
                Navigator.pop(dialogContext);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                if (_textFieldController.text.isNotEmpty) {
                  // Use the original context, not the dialog context
                  context.read<GroupsBloc>().add(
                    CreateGroup(_textFieldController.text),
                  );
                  // TODO: Still need a logging system
                  Group.saveGroupsToFile(
                    context.read<GroupsBloc>().getGroups(),
                  );
                  _textFieldController.clear();
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

typedef MenuEntry = DropdownMenuEntry<GroupRoles>;

class RightSide extends StatelessWidget {
  RightSide({super.key});

  final List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    GroupRoles.values.map<MenuEntry>(
      (role) => MenuEntry(value: role, label: role.name),
    ),
  );
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, groupState) {
          if (groupState.chosenGroup == null) return Container();
          final groupMemberIds =
              groupState.chosenGroup?.groupMemberIds.keys ?? [];
          return Stack(
            children: [
              Container(
                color: backgroundStartColor,
                child: ListView(
                  children:
                      Group.getGroupMembers(
                        groupMemberIds,
                        groupState.users,
                      ).map((user) {
                        return Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  "Name: ${user.firstName} ${user.lastName}",
                                ),
                              ),
                            ),
                            DropdownMenu<GroupRoles>(
                              initialSelection: groupState
                                  .chosenGroup
                                  ?.groupMemberIds[user.id],
                              dropdownMenuEntries: menuEntries,
                              onSelected: (value) {
                                if (value != null) {
                                  context.read<GroupsBloc>().add(
                                    ChangeGroupMemberRole(
                                      group: groupState.chosenGroup!,
                                      userId: user.id,
                                      newRole: value,
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.person_remove),
                              onPressed: () => {
                                context.read<GroupsBloc>().add(
                                  RemoveMember(
                                    groupState.chosenGroup!.id,
                                    user,
                                  ),
                                ),
                              },
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton.extended(
                  label: Text("Add User"),
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _displayTextInputDialog(context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    User? selectedUser;

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<GroupsBloc>(),
          child: AlertDialog(
            title: Text('Add User'),
            content: UserSearchView(
              onUserSelected: (user) {
                selectedUser = user;
              },
            ),
            actions: <Widget>[
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  // Use the original context, not the dialog context
                  if (selectedUser != null) {
                    final groupsBloc = context.read<GroupsBloc>();
                    Group? currentGroup = groupsBloc.state.chosenGroup;
                    context.read<GroupsBloc>().add(
                      AddMember(currentGroup!, selectedUser!),
                    );
                  }

                  Group.saveGroupsToFile(
                    context.read<GroupsBloc>().getGroups(),
                  );
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
