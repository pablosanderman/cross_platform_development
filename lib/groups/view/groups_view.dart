import 'package:flutter/material.dart';

import '../cubit/groups_cubit.dart';


class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(  // Add this to make it fill available space
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: LeftSide(),
          ),
          Expanded(
            flex: 3,
            child: const RightSide(),
          ),
        ],
      ),
    );
  }
}

const backgroundStartColor = Color(0xFFFFD500);

class LeftSide extends StatelessWidget {
  LeftSide({super.key});
  final TextEditingController _textFieldController = TextEditingController();

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                print(_textFieldController.text);
                GroupsCubit.instance.createGroup(_textFieldController.value.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Create Group"),
        icon: Icon(Icons.add),
        onPressed: () {
          _displayTextInputDialog(context);
        },
        
      ),
      body: Container(
        width: double.infinity,
        color: backgroundStartColor,
        child: Column(
          children: <Widget>[
            Material(
              child: ListTile(
                title: Text("test"),
              ),
            )
          ],
        ),
      ),
    );
  }

}

class RightSide extends StatelessWidget {
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundStartColor,
      child: Column(
        children: [
          Text("Group Management")
        ],
      ),
    );
  }
}