import 'package:cross_platform_development/groups/cubit/groups_bloc.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_development/groups/groups.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupsBloc(),
      child: const GroupsView(),
    );
  }
}