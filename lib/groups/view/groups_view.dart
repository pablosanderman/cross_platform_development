import 'package:cross_platform_development/groups/cubit/groups_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/groups_bloc.dart';
import '../cubit/groups_event.dart';

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
          Expanded(flex: 3, child: const RightSide()),
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
    context.read<GroupsBloc>();
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
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {

    return Container(
      height: MediaQuery.of(context).size.height,
      color: backgroundStartColor,
      child: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, groupState) {
          if(groupState.chosenGroup == null) return Container();
          final groupMembers = groupState.chosenGroup?.groupMembers;
          return ListView(
            children: groupMembers!.keys.map((person) {
              return ListTile(
                tileColor: Colors.blueAccent,
                title: Text("Name: ${person.firstName} ${person.lastName}"),
              );
            }).toList(),
          );
      },
    )
    );
  }
}
