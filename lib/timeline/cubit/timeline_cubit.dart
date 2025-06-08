import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:cross_platform_development/timeline/models/models.dart';
import 'timeline_state.dart';

/// Extension to add layout-specific properties to Event
extension EventLayout on Event {
  /// The effective end time for layout purposes, ensuring a minimum duration
  /// for visual spacing and text display
  DateTime get layoutEndTime {
    const minSpan = Duration(minutes: 180);
    if (!hasDuration) return effectiveStartTime.add(minSpan);
    final actualSpan = duration!;
    return actualSpan < minSpan
        ? effectiveStartTime.add(minSpan)
        : effectiveEndTime!;
  }
}

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
    final raw = await rootBundle.loadString('data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final events = (data['events'] as List)
        .map((e) => Event.fromJson(e))
        .toList()
        .cast<Event>();
    events.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));

    // Calculate visible window based on events
    DateTime visibleStart;
    DateTime visibleEnd;

    if (events.isEmpty) {
      visibleStart = DateTime.now().subtract(const Duration(hours: 2));
      visibleEnd = DateTime.now().add(const Duration(hours: 6));
    } else {
      final firstEvent = events.first;

      // Find the actual latest end time considering layout end times for all events
      DateTime latestEndTime = firstEvent.effectiveStartTime;
      for (Event event in events) {
        if (event.layoutEndTime.isAfter(latestEndTime)) {
          latestEndTime = event.layoutEndTime;
        }
      }

      visibleStart = firstEvent.effectiveStartTime.subtract(
        const Duration(hours: 1),
      );
      visibleEnd = latestEndTime.add(const Duration(hours: 1));
    }

    // Build rows with non-overlapping event placement
    final rows = _buildRows(events);

    emit(
      state.copyWith(
        events: events,
        visibleStart: visibleStart,
        visibleEnd: visibleEnd,
        rows: rows,
      ),
    );
  }

  List<TimelineRow> _buildRows(List<Event> events) {
    List<TimelineRow> rows = [];

    for (Event event in events) {
      bool placed = false;

      // Try to place event in existing rows
      for (int i = 0; i < rows.length; i++) {
        if (_canPlaceEventInRow(event, rows[i])) {
          List<Event> updatedEvents = [...rows[i].events, event];
          rows[i] = TimelineRow(
            index: rows[i].index,
            events: updatedEvents,
            height: rows[i].height,
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

    return rows;
  }

  bool _canPlaceEventInRow(Event event, TimelineRow row) {
    // Check if event overlaps with any event in this row
    for (Event rowEvent in row.events) {
      if (_eventsOverlap(event, rowEvent)) {
        return false;
      }
    }
    return true;
  }

  bool _eventsOverlap(Event a, Event b) {
    return a.effectiveStartTime.isBefore(b.layoutEndTime) &&
        a.layoutEndTime.isAfter(b.effectiveStartTime);
  }

  /// Reorder rows by moving a row from one index to another
  void reorderRows(int fromIndex, int toIndex) {
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= state.rows.length ||
        toIndex >= state.rows.length) {
      return;
    }

    final rows = List<TimelineRow>.from(state.rows);
    final draggedRow = rows.removeAt(fromIndex);
    rows.insert(toIndex, draggedRow);

    // Update row indices to maintain consistency
    final updatedRows = rows.asMap().entries.map((entry) {
      return TimelineRow(
        index: entry.key,
        events: entry.value.events,
        height: entry.value.height,
      );
    }).toList();

    emit(state.copyWith(rows: updatedRows));
  }
}
