import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// {@template events_repository}
/// Repository for loading and managing events data.
/// Provides a single source of truth for event data across the app.
/// {@endtemplate}
class EventsRepository {
  /// {@macro events_repository}
  const EventsRepository();

  /// Load all events from the JSON data file
  Future<List<Event>> loadEvents() async {
    final raw = await rootBundle.loadString('events.json');
    final data = jsonDecode(raw) as List<dynamic>;
    final events = data
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
    events.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
    return events;
  }

  /// Load events that have geographic coordinates (for map display)
  Future<List<Event>> loadEventsWithCoordinates() async {
    final events = await loadEvents();
    return events.where((event) => event.hasCoordinates).toList();
  }

  /// Load a specific event by ID
  Future<Event?> loadEvent(String eventId) async {
    final events = await loadEvents();
    try {
      return events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  /// Load events of a specific type
  Future<List<Event>> loadEventsByType(EventType type) async {
    final events = await loadEvents();
    return events.where((event) => event.type == type).toList();
  }

  /// Load events within a date range
  Future<List<Event>> loadEventsInDateRange(DateTime start, DateTime end) async {
    final events = await loadEvents();
    return events.where((event) {
      final eventStart = event.effectiveStartTime;
      final eventEnd = event.effectiveEndTime ?? eventStart;
      
      // Check if event overlaps with the requested range
      return eventStart.isBefore(end) && eventEnd.isAfter(start);
    }).toList();
  }

  /// Load events that have active discussions (messages in the last 30 days)
  Future<List<Event>> loadEventsWithRecentDiscussions() async {
    final events = await loadEvents();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return events.where((event) {
      return event.discussion.any((message) => 
        message.timestamp.isAfter(thirtyDaysAgo));
    }).toList();
  }
}