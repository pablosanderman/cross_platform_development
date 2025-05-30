import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:cross_platform_development/timeline/models/models.dart';
import 'timeline_state.dart';

/// {@template timeline_cubit}
/// A [Cubit] which manages a [TimelineState] as its state.
/// {@endtemplate}
class TimelineCubit extends Cubit<TimelineState> {
  /// {@macro timeline_cubit}
  TimelineCubit()
    : super(
        TimelineState(
          visibleStart: DateTime.now().subtract(const Duration(hours: 2)),
          visibleEnd: DateTime.now().add(const Duration(hours: 6)),
        ),
      );

  Future<void> loadTimeline() async {
    await _loadEvents();
    _loadRows();
  }

  Future<void> _loadEvents() async {
    final response = await rootBundle.loadString('data.json');
    final data = jsonDecode(response);
    final events = data['events']
        .map((event) => Event.fromJson(event))
        .toList()
        .cast<Event>();
    emit(state.copyWith(events: events));
  }

  void _loadRows() {
    List<Event> events = state.events;
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Adjust visible window to center around events
    if (events.isNotEmpty) {
      final firstEvent = events.first;
      final lastEvent = events.last;
      final startTime = firstEvent.startTime.subtract(const Duration(hours: 1));
      final endTime = (lastEvent.endTime ?? lastEvent.startTime).add(
        const Duration(hours: 1),
      );

      emit(state.copyWith(visibleStart: startTime, visibleEnd: endTime));
    }

    List<TimelineRow> rows = [];

    for (Event event in events) {
      bool placed = false;

      // Try to place event in existing rows
      for (int i = 0; i < rows.length; i++) {
        TimelineRow row = rows[i];
        bool canFitInRow = true;

        // Check if event overlaps with any event in this row
        for (Event rowEvent in row.events) {
          if (_eventsOverlap(event, rowEvent)) {
            canFitInRow = false;
            break;
          }
        }

        // If no overlap, add to this row
        if (canFitInRow) {
          List<Event> updatedEvents = [...row.events, event];
          rows[i] = TimelineRow(
            index: row.index,
            events: updatedEvents,
            height: row.height,
          );
          placed = true;
          break;
        }
      }

      // If couldn't place in any existing row, create new row
      if (!placed) {
        rows.add(TimelineRow(index: rows.length, events: [event]));
      }
    }

    // Update state with the new rows
    emit(state.copyWith(rows: rows));
  }

  bool _eventsOverlap(Event event1, Event event2) {
    DateTime event1EffectiveEnd = _getEffectiveEndTime(event1);
    DateTime event2EffectiveEnd = _getEffectiveEndTime(event2);

    return event1.startTime.isBefore(event2EffectiveEnd) &&
        event1EffectiveEnd.isAfter(event2.startTime);
  }

  /// Calculates the effective end time including text space
  DateTime _getEffectiveEndTime(Event event) {
    DateTime actualEnd;

    if (_isPointEvent(event)) {
      // Point events have no duration, but we need space for the circle
      actualEnd = event.startTime.add(const Duration(minutes: 5));
    } else {
      actualEnd = event.endTime!;
    }

    // If text goes to the right, add extra time for text space
    if (_hasTextToRight(event)) {
      // Estimate text width based on title length (rough approximation)
      // Assume ~8 characters per 30 minutes at normal zoom
      final textMinutes = (event.title.length / 8 * 30).ceil();
      actualEnd = actualEnd.add(Duration(minutes: textMinutes.clamp(15, 120)));
    }

    return actualEnd;
  }

  /// Determines if an event is a single point event (no end time)
  bool _isPointEvent(Event event) {
    return event.endTime == null;
  }

  /// Determines if a period event is too short and needs text to the right
  bool _isShortPeriodEvent(Event event) {
    if (_isPointEvent(event)) return false;

    // Consider event "short" if less than 30 minutes
    final duration = event.endTime!.difference(event.startTime);
    return duration.inMinutes < 30;
  }

  /// Determines if event text should be displayed to the right
  bool _hasTextToRight(Event event) {
    return _isPointEvent(event) || _isShortPeriodEvent(event);
  }
}
