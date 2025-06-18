import 'package:cross_platform_development/groups/groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../widget/generic_search_widget.dart';

// class EventSearchView extends StatelessWidget {
//   const EventSearchView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final users = context.read<GroupsBloc>().state.users;
//     final groupMember = context.read<GroupsBloc>().state.chosenGroup?.groupMemberIds;
//
//     return GenericSearchBar<User>(
//       loadItems: () => context.read<GroupsBloc>().state.users,
//       filter: (user, query) =>
//           user.id.contains(query),
//       itemBuilder: (event) {
//
//       },
//       onItemSelected: (event) {
//
//       },
//     );
//   }
// }