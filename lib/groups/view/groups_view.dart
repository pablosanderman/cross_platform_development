import 'dart:collection';

import 'package:cross_platform_development/search/view/user_search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../handle_fake_account.dart';
import '../../shared/utils/platform_utils.dart';
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
    return PlatformUtils.isMobile
      ? const SafeArea(child: MobileGroupsNavigation())
      : Row(
          children: [
            // On desktop: side by side
            Expanded(flex: 1, child: LeftSide()),
            Expanded(flex: 3, child: RightSide()),
          ],
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

class MobileGroupsNavigation extends StatelessWidget {
  const MobileGroupsNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupsBloc, GroupsState>(
      builder: (context, state) {
        // Debug: print('Mobile navigation - chosen group: ${state.chosenGroup?.name ?? 'none'}');
        // Show RightSide (members list) when a group is selected
        if (state.chosenGroup != null) {
          return const MobileRightSideWrapper();
        }
        // Show LeftSide (groups list) by default
        return LeftSide();
      },
    );
  }
}

class MobileRightSideWrapper extends StatelessWidget {
  const MobileRightSideWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupsBloc, GroupsState>(
      builder: (context, state) {
        return Stack(
          children: [
            // Use existing RightSide component
            RightSide(),
            // Add back button overlay for mobile
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                onPressed: () {
                  // Navigate back to groups list by clearing selected group
                  // Debug: print('Back button pressed - clearing selected group');
                  context.read<GroupsBloc>().add(ChooseGroup(null));
                },
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LeftSide extends StatelessWidget {
  LeftSide({super.key});

  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundStartColor,
            child: BlocBuilder<GroupsBloc, GroupsState>(
              builder: (context, groupState) {
                // Debug information  
                // print('Groups loaded: ${groupState.groups.length}');
                // print('Users loaded: ${groupState.users.length}');
                // print('Logged in user: ${FakeAccount.loggedInUser?.firstName}');
                
                final userGroups = groupState.groups
                    .where(
                      (group) =>
                          FakeAccount.loggedInUser != null &&
                          group.groupMemberIds.keys.contains(
                            FakeAccount.loggedInUser?.id,
                          ),
                    )
                    .toList();
                
                // print('Filtered user groups: ${userGroups.length}');
                
                if (userGroups.isEmpty && FakeAccount.loggedInUser != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No groups found for ${FakeAccount.loggedInUser!.firstName}.\nTap + to create a group.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                } else if (userGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Loading groups...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView(
                  padding: PlatformUtils.isMobile 
                    ? const EdgeInsets.all(8.0)
                    : EdgeInsets.zero,
                  children: [
                    ...userGroups.map((group) {
                        return Container(
                          margin: PlatformUtils.isMobile 
                            ? const EdgeInsets.symmetric(vertical: 4.0)
                            : EdgeInsets.zero,
                          child: Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text(
                                    group.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  onTap: () {
                                    context.read<GroupsBloc>().add(
                                      ChooseGroup(group),
                                    );
                                  },
                                ),
                              ),
                              if (!PlatformUtils.isMobile) ...[
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
                              ] else ...[
                                // Mobile: Just icons without text
                                IconButton(
                                  icon: const Icon(Icons.logout, size: 20),
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
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () {
                                    context.read<GroupsBloc>().add(
                                      DeleteGroup(group.id),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PlatformUtils.isMobile
                ? FloatingActionButton(
                    onPressed: () {
                      _displayTextInputDialog(context);
                    },
                    child: const Icon(Icons.add),
                  )
                : FloatingActionButton.extended(
                    label: const Text("Create Group"),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _displayTextInputDialog(context);
                    },
                  ),
            ),
          ),
        ],
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
    return BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, groupState) {
          if (groupState.chosenGroup == null) return Container();
          final groupMemberIds =
              groupState.chosenGroup?.groupMemberIds.keys ?? [];
          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: backgroundStartColor,
                child: ListView(
                  padding: PlatformUtils.isMobile 
                    ? const EdgeInsets.all(8.0)
                    : EdgeInsets.zero,
                  children:
                      Group.getGroupMembers(
                        groupMemberIds,
                        groupState.users,
                      ).map((user) {
                        return Container(
                          margin: PlatformUtils.isMobile 
                            ? const EdgeInsets.symmetric(vertical: 4.0)
                            : EdgeInsets.zero,
                          child: Row(
                            children: [
                              Expanded(
                                flex: PlatformUtils.isMobile ? 2 : 1,
                                child: ListTile(
                                  title: Text(
                                    "Name: ${user.firstName} ${user.lastName}",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: PlatformUtils.isMobile ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            Flexible(
                              child: DropdownMenu<GroupRoles>(
                                width: PlatformUtils.isMobile ? 100 : null,
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
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.person_remove,
                                size: PlatformUtils.isMobile ? 20 : 24,
                              ),
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
                        ),
                      );
                      }).toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PlatformUtils.isMobile
                    ? FloatingActionButton(
                        onPressed: () {
                          _displayTextInputDialog(context);
                        },
                        child: const Icon(Icons.person_add),
                      )
                    : FloatingActionButton.extended(
                        label: const Text("Add User"),
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _displayTextInputDialog(context);
                        },
                      ),
                ),
              ),
            ],
          );
        },
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
