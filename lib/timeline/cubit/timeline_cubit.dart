import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/map/map.dart';
import 'timeline_state.dart';
import 'package:flutter/rendering.dart';

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
  TimelineCubit({EventsRepository? eventsRepository, MapCubit? mapCubit})
    : _eventsRepository = eventsRepository ?? const EventsRepository(),
      _mapCubit = mapCubit,
      super(
        TimelineState(
          visibleStart: DateTime.now().subtract(const Duration(hours: 2)),
          visibleEnd: DateTime.now().add(const Duration(hours: 6)),
        ),
      );

  final EventsRepository _eventsRepository;
  MapCubit? _mapCubit;

  Future<void> loadEvents() async {
    emit(state.copyWith(events: await _eventsRepository.loadEvents()));
  }

  Future<void> addEvent(String eventTitle) async {
    var random = new Random();
    var maxInt = 9;
    final List<Event> newEvents = [...state.events];
    String eventId = "evt-"
        "${random.nextInt(maxInt)}"
        "${random.nextInt(maxInt)}"
        "${random.nextInt(maxInt)}"
        "${random.nextInt(maxInt)}";
    newEvents.add(Event(
        id: eventId,
        type: EventType.period,
        title: eventTitle)
    );

    emit(state.copyWith(events: newEvents));
  }

  Future<void> loadTimeline() async {
    await loadEvents();
    final List<Event> events = state.events;
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
    if (fromIndex == toIndex) {
      return; // No-op for same position
    }

    if (fromIndex < 0 ||
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

  /// Update the height of a specific row
  void updateRowHeight(int rowIndex, double newHeight) {
    if (rowIndex < 0 || rowIndex >= state.rows.length) {
      return;
    }

    // Ensure minimum height is the default row height, and reasonable maximum
    final minHeight = defaultRowHeight; // Can't go smaller than default
    const maxHeight = 250.0;
    final constrainedHeight = newHeight.clamp(minHeight, maxHeight);

    final rows = List<TimelineRow>.from(state.rows);
    final currentRow = rows[rowIndex];

    rows[rowIndex] = TimelineRow(
      index: currentRow.index,
      events: currentRow.events,
      height: constrainedHeight,
    );

    emit(state.copyWith(rows: rows));
  }

  /// Get the default row height
  static const double defaultRowHeight = 75.0;

  /// Set hovered event and notify map to highlight corresponding marker
  void setHoveredEvent(Event? event) {
    emit(state.copyWith(hoveredEvent: event));
    _mapCubit?.highlightEvent(event);
  }

  /// Clear hovered event
  void clearHoveredEvent() {
    emit(state.copyWith(clearHoveredEvent: true));
    _mapCubit?.clearHighlight();
  }

  /// Scroll timeline to show a specific event
  void scrollToEvent(Event event) {
    // Trigger programmatic scrolling in the view without changing timeline bounds
    emit(state.copyWith(scrollToEvent: event));
  }

  /// Clear the scroll to event flag (called after scrolling is complete)
  void clearScrollToEvent() {
    emit(state.copyWith(clearScrollToEvent: true));
  }

  /// Set the MapCubit reference (used to resolve circular dependency)
  void setMapCubit(MapCubit mapCubit) {
    _mapCubit = mapCubit;
  }

  /// Select an event (shared between map and timeline)
  void selectEvent(Event? event) {
    emit(state.copyWith(selectedEvent: event));
    // Notify map to update its visual state
    _mapCubit?.updateSelectedEvent(event);
  }

  /// Clear selected event
  void clearSelection() {
    emit(state.copyWith(clearSelectedEvent: true));
    // Notify map to update its visual state
    _mapCubit?.updateSelectedEvent(null);
  }

  /// Save the current transformation matrix to preserve scroll/zoom state
  void saveTransformationMatrix(Matrix4 matrix) {
    emit(state.copyWith(transformationMatrix: Matrix4.copy(matrix)));
  }

  /// Get the saved transformation matrix, or null if none exists
  Matrix4? getSavedTransformationMatrix() {
    if (state.transformationMatrix != null) {
      return Matrix4.copy(state.transformationMatrix!);
    } else {
      return null;
    }
  }

  /// Clear the saved transformation matrix
  void clearTransformationMatrix() {
    emit(state.copyWith(clearTransformationMatrix: true));
  }
}
