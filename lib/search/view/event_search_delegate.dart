import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../timeline/timeline.dart';
import '../utils/event_search_utils.dart';

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
        backgroundColor: Color.fromARGB(255, 40, 40, 40),
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
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
      icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              .where((event) => EventSearchUtils.filterEvent(event, query))
              .toList();

    if (filteredEvents.isEmpty) {
      return Container(
        color: const Color.fromARGB(255, 30, 30, 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                query.isEmpty ? Icons.search : Icons.search_off,
                size: 64,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                query.isEmpty
                    ? 'Start typing to search events'
                    : 'No events found',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color.fromARGB(255, 30, 30, 30),
      child: ListView.builder(
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 45, 45, 45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: EventListTile(
              event: event,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              subtitleStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              onTap: () {
                EventSearchUtils.selectEvent(context, event);
                close(context, event);
              },
            ),
          );
        },
      ),
    );
  }
}
