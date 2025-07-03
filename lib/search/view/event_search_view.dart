import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../timeline/timeline.dart';
import '../widget/generic_search_widget.dart';
import '../utils/event_search_utils.dart';

/// Pure search widget for desktop navbar usage
/// Mobile uses showSearch() with EventSearchDelegate instead
class EventSearchView extends StatelessWidget {
  const EventSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      builder: (context, timelineState) {
        if (timelineState.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GenericSearchBar<Event>(
          loadItems: () => timelineState.events,
          filter: EventSearchUtils.filterEvent,
          itemBuilder: (event) => Text(
            "${event.title}   ${EventSearchUtils.formatEventTime(event)}",
          ),
          itemTitle: (event) => event.title,
          onItemSelected: (event) {
            EventSearchUtils.selectEvent(context, event);
          },
          leadingIcon: const Icon(Icons.search),
        );
      },
    );
  }
}
