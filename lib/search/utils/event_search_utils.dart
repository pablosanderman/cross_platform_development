import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../navigation/navigation.dart';
import '../../timeline/timeline.dart';

/// Shared utilities for event search functionality
class EventSearchUtils {
  /// Filter events by title containing the query
  static bool filterEvent(Event event, String query) {
    return event.title.toLowerCase().contains(query.toLowerCase());
  }

  /// Format event time display
  static String formatEventTime(Event event) {
    final start = event.startTime != null
        ? DateFormat('HH:mm:ss').format(event.startTime!)
        : "No Start";
    final end = event.endTime != null
        ? DateFormat('HH:mm:ss').format(event.endTime!)
        : "No End";
    return "Date: $start --- $end";
  }

  /// Handle event selection - navigate to timeline and select event
  static void selectEvent(BuildContext context, Event event) {
    context.read<NavigationBloc>().add(ShowTimeline());
    context.read<TimelineCubit>().scrollToEvent(event);
    context.read<TimelineCubit>().selectEvent(event);
  }
}

/// Reusable event list tile widget
class EventListTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const EventListTile({
    super.key,
    required this.event,
    required this.onTap,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        event.title,
        style: titleStyle ?? const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        EventSearchUtils.formatEventTime(event),
        style: subtitleStyle ?? const TextStyle(color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
