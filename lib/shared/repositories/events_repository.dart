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
    final raw = await rootBundle.loadString('data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final events = (data['events'] as List)
        .map((e) => Event.fromJson(e))
        .toList()
        .cast<Event>();
    events.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
    return events;
  }

  /// Load events that have geographic coordinates (for map display)
  Future<List<Event>> loadEventsWithCoordinates() async {
    final events = await loadEvents();
    return events.where((event) => event.hasCoordinates).toList();
  }
}
