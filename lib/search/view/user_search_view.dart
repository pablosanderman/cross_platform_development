import 'package:cross_platform_development/groups/groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widget/generic_search_widget.dart';

class UserSearchView extends StatelessWidget {
  final void Function(User user) onUserSelected;

  const UserSearchView({super.key, required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupsBloc, GroupsState>(
      builder: (context, groupState) {
        if (groupState.chosenGroup == null) {
          return const CircularProgressIndicator();
        }
        final nonMembers = Group.getNonGroupMembers(
          groupState.chosenGroup!.groupMemberIds.keys,
          groupState.users,
        );
        if (nonMembers.isEmpty) {
          return const CircularProgressIndicator();
        }

        return GenericSearchBar<User>(
          loadItems: () => nonMembers,
          filter: (user, query) =>
              "${user.firstName} ${user.lastName}".contains(query),
          itemBuilder: (user) {
            return Text("${user.firstName} ${user.lastName}");
          },
          onItemSelected: (user) {
            onUserSelected(user);
          },
          itemTitle: (user) => "${user.firstName} ${user.lastName}",
        );
      },
    );
  }
}
