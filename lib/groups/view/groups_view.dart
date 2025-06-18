import 'package:cross_platform_development/groups/cubit/groups_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../HandleFakeAccount.dart';
import '../cubit/groups_bloc.dart';
import '../cubit/groups_event.dart';
import '../models/models.dart';

const backgroundStartColor = Color(0xFFFFD500);

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  @override
  Widget build(BuildContext context) {
    // Add this to make it fill available space
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
    final loggedInUser = context.read<GroupsBloc>().state.users.where((p) => p.firstName == "Andrew");
    if(loggedInUser.isNotEmpty) {
      FakeAccount.loggedInUser = loggedInUser.single;
    }

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
    
    return SizedBox(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              color: backgroundStartColor,
              child: BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, groupState) {
                  return ListView(
                    children: groupState.groups.map((group) {
                      return ListTile(
                        tileColor: Colors.blueAccent,
                        title: Text(group.name),
                        onTap: () => {
                          context.read<GroupsBloc>().add(
                            ChooseGroup(group)
                          )
                        },
                      );
                    }).toList(),
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
            )
          ],
        )
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
                  context.read<GroupsBloc>().createGroup(_textFieldController.text);
                  print('Creating group: ${_textFieldController.text}');
                  Group.saveGroupsToFile(context.read<GroupsBloc>().getGroups());
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

class RightSide extends StatelessWidget {
  RightSide({super.key});
  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      child: Stack(
        children: [
          Container(
              height: MediaQuery.of(context).size.height,
              color: backgroundStartColor,
              child: BlocBuilder<GroupsBloc, GroupsState>(
                builder: (context, groupState) {
                  if(groupState.chosenGroup == null) return Container();
                  final groupMemberIds = groupState.chosenGroup?.groupMemberIds.keys ?? [];
                  final groupMembers = groupState.users
                      .where((p) => groupMemberIds.contains(p.id))
                      .toList();
                  return ListView(
                    children: groupMembers.map((person) {
                      return ListTile(
                        tileColor: Colors.blueAccent,
                        title: Text("Name: ${person.firstName} ${person.lastName}"),
                      );
                    }).toList(),
                  );
                },
              )
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
          )
        ],
      )

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
                  context.read<GroupsBloc>().createGroup(_textFieldController.text);
                  print('Creating group: ${_textFieldController.text}');
                  Group.saveGroupsToFile(context.read<GroupsBloc>().getGroups());
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
