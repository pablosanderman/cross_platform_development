import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../timeline/timeline.dart';
import '../widget/generic_search_widget.dart';

/// Pure search widget that works on any platform
/// Can be used in navbar (desktop) or as full-screen page (mobile)
class EventSearchView extends StatelessWidget {
  final bool fullScreen;

  const EventSearchView({super.key, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      builder: (context, timelineState) {
        if (timelineState.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final searchWidget = GenericSearchBar<Event>(
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
            // Navigate to timeline and select event
            context.read<NavigationBloc>().add(ShowTimeline());
            context.read<TimelineCubit>().scrollToEvent(event);
            context.read<TimelineCubit>().selectEvent(event);

            // If full-screen, navigate back after selection
            if (fullScreen) {
              Navigator.of(context).pop();
            }
          },
          leadingIcon: const Icon(Icons.search),
          fullScreen: fullScreen,
        );

        // If full-screen, wrap in Scaffold with app bar
        if (fullScreen) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 30, 30, 30),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 40, 40, 40),
              foregroundColor: Colors.white,
              title: const Text('Search Events'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: searchWidget,
            ),
          );
        }

        // Regular widget for navbar/component usage
        return searchWidget;
      },
    );
  }
}
