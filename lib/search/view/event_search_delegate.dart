import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../navigation/navigation.dart';
import '../../timeline/timeline.dart';

/// Search delegate for full-screen event search using showSearch()
class EventSearchDelegate extends SearchDelegate<Event?> {
  final List<Event> events;

  EventSearchDelegate({required this.events});

  @override
  String get searchFieldLabel => 'Search events...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 175, 169, 169),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredEvents = query.isEmpty
        ? events
        : events
              .where(
                (event) =>
                    event.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Text('No events found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      color: const Color.fromARGB(255, 30, 30, 30),
      child: ListView.builder(
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          final start = event.startTime != null
              ? DateFormat('HH:mm:ss').format(event.startTime!)
              : "No Start";
          final end = event.endTime != null
              ? DateFormat('HH:mm:ss').format(event.endTime!)
              : "No End";

          return ListTile(
            title: Text(
              event.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Date: $start --- $end",
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              // Navigate to timeline and select event
              context.read<NavigationBloc>().add(ShowTimeline());
              context.read<TimelineCubit>().scrollToEvent(event);
              context.read<TimelineCubit>().selectEvent(event);

              // Close search and return
              close(context, event);
            },
          );
        },
      ),
    );
  }
}
