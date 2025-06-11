import 'package:flutter/material.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: const LeftSide(),
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
  const LeftSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: backgroundStartColor,
        child: Column(children: [Text("Groups View")]),
      ),
    );
  }
}

class RightSide extends StatelessWidget {
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: backgroundStartColor,
        child: Column(children: [Text("Group Management")]),
      ),
    );
  }
}