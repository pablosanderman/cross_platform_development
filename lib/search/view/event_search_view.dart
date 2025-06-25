import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../timeline/timeline.dart';
import '../widget/generic_search_widget.dart';

class EventSearchView extends StatelessWidget {
  const EventSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      builder: (context, timelineState) {
        if (timelineState.events.isEmpty) {
          return const CircularProgressIndicator(); // or placeholder
        }

        return GenericSearchBar<Event>(
          loadItems: () => timelineState.events,
          filter: (event, query) =>
              event.title.toLowerCase().contains(query.toLowerCase()),
          itemBuilder: (event) {
            final start = event.startTime != null
                ? DateFormat('HH:mm:ss').format(event.startTime!)
                : "No Start";
            final end = event.endTime != null
                ? DateFormat('HH:mm:ss').format(event.endTime!)
                : "No End";
            return Text("${event.title}   Date: $start --- $end");
          },
          itemTitle: (event) => event.title,
          onItemSelected: (event) {
            context.read<NavigationBloc>().add(ShowTimeline());
            context.read<TimelineCubit>().scrollToEvent(event);
            context.read<TimelineCubit>().selectEvent(event);
          },
          leadingIcon: const Icon(Icons.search),
        );
      },
    );
  }
}
