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

    // Create rows for events
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
    const defaultDuration = Duration(minutes: 180);

    if (_isPointEvent(event)) {
      // Point events have no duration, so they get the full 180 minutes
      return event.startTime.add(defaultDuration);
    } else {
      // Period events get at least 180 minutes, or their actual duration if longer
      final actualDuration = event.endTime!.difference(event.startTime);

      if (actualDuration.inMinutes < defaultDuration.inMinutes) {
        return event.startTime.add(defaultDuration);
      } else {
        return event.endTime!;
      }
    }
  }

  /// Determines if an event is a single point event (no end time)
  bool _isPointEvent(Event event) {
    return event.endTime == null;
  }
}
