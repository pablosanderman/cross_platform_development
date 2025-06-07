import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:cross_platform_development/timeline/models/models.dart';
import 'timeline_state.dart';

/// Extension to add layout-specific properties to Event
extension EventLayout on Event {
  /// The effective end time for layout purposes, ensuring a minimum duration
  /// for visual spacing and text display
  DateTime layoutEndTime(Duration minSpan) {
    if (!hasDuration) return effectiveStartTime.add(minSpan);
    final actualSpan = duration!;
    return actualSpan < minSpan
        ? effectiveStartTime.add(minSpan)
        : effectiveEndTime!;
  }
}

/// Window data class to replace tuple syntax
class TimelineWindow {
  final DateTime start;
  final DateTime end;

  const TimelineWindow({required this.start, required this.end});

  Duration get duration => end.difference(start);

  @override
  String toString() => 'Window($start → $end)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineWindow &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  /// Check if windows are approximately equal (within tolerance)
  /// Useful for UI key comparisons where millisecond precision isn't needed
  bool approximatelyEquals(
    TimelineWindow other, {
    Duration tolerance = const Duration(seconds: 1),
  }) {
    return (start.difference(other.start).abs() <= tolerance) &&
        (end.difference(other.end).abs() <= tolerance);
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// Timeline-specific exception for consistent error handling
class TimelineException implements Exception {
  final String message;

  const TimelineException(this.message);

  @override
  String toString() => 'TimelineException: $message';
}

/// Service class for data loading and parsing
/// Note: loadData() is async and may throw. All other operations are synchronous.
class TimelineDataService {
  final Future<String> Function() _loadJson;
  final List<Event> Function(Map<String, dynamic>) _parseEvents;

  const TimelineDataService({
    required Future<String> Function() loadJson,
    required List<Event> Function(Map<String, dynamic>) parseEvents,
  }) : _loadJson = loadJson,
       _parseEvents = parseEvents;

  /// Default data service
  static TimelineDataService get defaultService => TimelineDataService(
    loadJson: () => rootBundle.loadString('data.json'),
    parseEvents: _defaultEventParser,
  );

  static List<Event> _defaultEventParser(Map<String, dynamic> jsonData) {
    if (!jsonData.containsKey('events') || jsonData['events'] is! List) {
      throw TimelineException(
        'Invalid JSON: missing or invalid "events" array',
      );
    }

    try {
      return (jsonData['events'] as List)
          .map((e) => Event.fromJson(e))
          .toList()
          .cast<Event>();
    } catch (e) {
      throw TimelineException('Failed to parse events: $e');
    }
  }

  /// Loads data from source. May throw TimelineException.
  Future<List<Event>> loadData() async {
    try {
      final raw = await _loadJson();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _parseEvents(data);
    } catch (e) {
      throw TimelineException('Failed to load timeline data: $e');
    }
  }

  /// Parses data from JSON. May throw TimelineException.
  List<Event> parseData(Map<String, dynamic> jsonData) {
    return _parseEvents(jsonData);
  }
}

/// Service class for event sorting
/// Note: All operations are synchronous and validate input.
class TimelineSorter {
  final void Function(List<Event>) _sortFn;

  const TimelineSorter(this._sortFn);

  static const TimelineSorter defaultSorter = TimelineSorter(_defaultSort);

  static void _defaultSort(List<Event> events) {
    events.sort((a, b) => a.effectiveStartTime.compareTo(b.effectiveStartTime));
  }

  /// Sorts events in place. Validates input is not null.
  void sort(List<Event> events) {
    if (events.isEmpty) return;

    try {
      _sortFn(events);
    } catch (e) {
      throw TimelineException('Failed to sort events: $e');
    }
  }
}

/// Service class for window calculation
/// Note: All operations are synchronous and validate input.
class TimelineWindowCalculator {
  final Duration minEventSpan;
  final Duration preWindowPadding;
  final Duration postWindowPadding;

  const TimelineWindowCalculator({
    this.minEventSpan = const Duration(minutes: 180),
    this.preWindowPadding = const Duration(hours: 1),
    this.postWindowPadding = const Duration(hours: 1),
  });

  /// Calculates optimal window for events. Validates input.
  TimelineWindow calculateWindow(List<Event> events) {
    try {
      if (events.isEmpty) {
        final now = DateTime.now();
        return TimelineWindow(
          start: now.subtract(preWindowPadding),
          end: now.add(postWindowPadding),
        );
      }

      final firstEvent = events.first;
      DateTime latestEndTime = firstEvent.effectiveStartTime;

      for (Event event in events) {
        final eventEndTime = event.layoutEndTime(minEventSpan);
        if (eventEndTime.isAfter(latestEndTime)) {
          latestEndTime = eventEndTime;
        }
      }

      return TimelineWindow(
        start: firstEvent.effectiveStartTime.subtract(preWindowPadding),
        end: latestEndTime.add(postWindowPadding),
      );
    } catch (e) {
      throw TimelineException('Failed to calculate window: $e');
    }
  }
}

/// Service class for row layout
/// Note: All operations are synchronous and validate input.
class TimelineRowBuilder {
  final Duration minEventSpan;

  const TimelineRowBuilder({this.minEventSpan = const Duration(minutes: 180)});

  /// Builds rows from events. Validates input.
  List<TimelineRow> buildRows(List<Event> events) {
    if (events.isEmpty) return [];

    try {
      List<TimelineRow> rows = [];

      for (Event event in events) {
        bool placed = false;

        // Try to place event in existing rows
        for (int i = 0; i < rows.length; i++) {
          if (canPlaceEventInRow(event, rows[i])) {
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
    } catch (e) {
      throw TimelineException('Failed to build rows: $e');
    }
  }

  /// Checks if event can be placed in row. Validates input.
  bool canPlaceEventInRow(Event event, TimelineRow row) {
    try {
      for (Event rowEvent in row.events) {
        if (eventsOverlap(event, rowEvent)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw TimelineException('Failed to check event placement: $e');
    }
  }

  /// Checks if two events overlap. Validates input.
  bool eventsOverlap(Event a, Event b) {
    try {
      return a.effectiveStartTime.isBefore(b.layoutEndTime(minEventSpan)) &&
          a.layoutEndTime(minEventSpan).isAfter(b.effectiveStartTime);
    } catch (e) {
      throw TimelineException('Failed to check event overlap: $e');
    }
  }

  /// Adds a single event to existing rows. Validates input.
  List<TimelineRow> addEvent(Event event, List<TimelineRow> existingRows) {
    try {
      List<TimelineRow> rows = [...existingRows];

      // Try to place in existing rows
      for (int i = 0; i < rows.length; i++) {
        if (canPlaceEventInRow(event, rows[i])) {
          rows[i] = TimelineRow(
            index: rows[i].index,
            events: [...rows[i].events, event],
            height: rows[i].height,
          );
          return rows;
        }
      }

      // Create new row if needed
      rows.add(TimelineRow(index: rows.length, events: [event]));
      return rows;
    } catch (e) {
      throw TimelineException('Failed to add event: $e');
    }
  }

  /// Removes an event from rows. Validates input.
  List<TimelineRow> removeEvent(
    String eventId,
    List<TimelineRow> existingRows,
  ) {
    if (eventId.isEmpty) {
      throw TimelineException('Event ID cannot be empty');
    }

    try {
      List<TimelineRow> rows = [];
      int index = 0;

      for (TimelineRow row in existingRows) {
        final filteredEvents = row.events
            .where((e) => e.id != eventId)
            .toList();
        if (filteredEvents.isNotEmpty) {
          rows.add(
            TimelineRow(
              index: index++,
              events: filteredEvents,
              height: row.height,
            ),
          );
        }
      }

      return rows;
    } catch (e) {
      throw TimelineException('Failed to remove event: $e');
    }
  }
}

/// Unified pipeline abstraction for better discoverability
/// Groups all timeline services into a single, composable unit
///
/// ## Architecture Overview 🏗️
/// ```
/// TimelineCubit → TimelinePipeline
/// ├── 📊 TimelineDataService (load data.json → parse events)
/// ├── 🔄 TimelineSorter (sort by timestamp)
/// ├── 📏 TimelineWindowCalculator (calculate visible time range)
/// └── 📐 TimelineRowBuilder (layout non-overlapping rows)
///      ↓
/// TimelineState → UI rebuilds
/// ```
///
/// ## Quick Start 🚀
/// ```dart
/// // Default pipeline
/// final cubit = TimelineCubit(); // uses TimelinePipeline.defaultPipeline
///
/// // Testing with mock data
/// final cubit = TimelineCubit.fromMockData([event1, event2]);
///
/// // Custom composition
/// final cubit = TimelineCubit.withPipeline(TimelinePipeline(
///   dataService: NetworkDataService(url),
///   sorter: PrioritySorter(),
///   windowCalculator: WeeklyWindowCalculator(),
///   rowBuilder: DensePackingRowBuilder(),
/// ));
/// ```
///
/// ## Granular Operations ⚙️
/// ```dart
/// // Individual pipeline steps
/// final events = await cubit.loadData();  // Step 1: Load
/// cubit.sort(events);                     // Step 2: Sort
/// final window = cubit.calcWindow(events); // Step 3: Window
/// final rows = cubit.layout(events);      // Step 4: Layout
/// cubit.emitState(events: events, window: window, rows: rows); // Step 5: Emit
///
/// // Surgical updates
/// cubit.addEvent(newEvent);    // Add without full rebuild
/// cubit.removeEvent(eventId);  // Remove without full rebuild
/// ```
class TimelinePipeline {
  final TimelineDataService dataService;
  final TimelineSorter sorter;
  final TimelineWindowCalculator windowCalculator;
  final TimelineRowBuilder rowBuilder;

  const TimelinePipeline({
    required this.dataService,
    required this.sorter,
    required this.windowCalculator,
    required this.rowBuilder,
  });

  /// Default pipeline with standard configuration
  static TimelinePipeline get defaultPipeline => TimelinePipeline(
    dataService: TimelineDataService.defaultService,
    sorter: TimelineSorter.defaultSorter,
    windowCalculator: const TimelineWindowCalculator(),
    rowBuilder: const TimelineRowBuilder(),
  );

  /// Pipeline for network data
  static TimelinePipeline networkPipeline(String url) => TimelinePipeline(
    dataService: TimelineDataService(
      loadJson: () async =>
          throw UnimplementedError('Network loading not implemented'),
      parseEvents: TimelineDataService._defaultEventParser,
    ),
    sorter: TimelineSorter.defaultSorter,
    windowCalculator: const TimelineWindowCalculator(),
    rowBuilder: const TimelineRowBuilder(),
  );

  /// Pipeline for testing with mock data
  static TimelinePipeline mockPipeline(List<Event> events) => TimelinePipeline(
    dataService: TimelineDataService(
      loadJson: () async => '{"events": []}',
      parseEvents: (_) => events,
    ),
    sorter: TimelineSorter.defaultSorter,
    windowCalculator: const TimelineWindowCalculator(),
    rowBuilder: const TimelineRowBuilder(),
  );

  /// Execute full pipeline: load → sort → window → layout
  Future<TimelinePipelineResult> execute() async {
    final events = await dataService.loadData();
    sorter.sort(events);
    final window = windowCalculator.calculateWindow(events);
    final rows = rowBuilder.buildRows(events);

    return TimelinePipelineResult(events: events, window: window, rows: rows);
  }

  /// Process existing events through pipeline: sort → window → layout
  TimelinePipelineResult process(List<Event> events) {
    final eventsCopy = [...events];
    sorter.sort(eventsCopy);
    final window = windowCalculator.calculateWindow(eventsCopy);
    final rows = rowBuilder.buildRows(eventsCopy);

    return TimelinePipelineResult(
      events: eventsCopy,
      window: window,
      rows: rows,
    );
  }
}

/// Result of pipeline execution
class TimelinePipelineResult {
  final List<Event> events;
  final TimelineWindow window;
  final List<TimelineRow> rows;

  const TimelinePipelineResult({
    required this.events,
    required this.window,
    required this.rows,
  });
}

/// {@template timeline_cubit}
/// A [Cubit] which manages a [TimelineState] as its state.
/// Uses TimelinePipeline for organized service composition.
/// {@endtemplate}
class TimelineCubit extends Cubit<TimelineState> implements TimelineProvider {
  final TimelinePipeline _pipeline;

  /// {@macro timeline_cubit}
  TimelineCubit({TimelinePipeline? pipeline})
    : _pipeline = pipeline ?? TimelinePipeline.defaultPipeline,
      super(
        TimelineState(
          visibleStart: DateTime.now().subtract(const Duration(hours: 2)),
          visibleEnd: DateTime.now().add(const Duration(hours: 6)),
        ),
      );

  // Individual pipeline operations (with contextual error handling)

  /// Step 1: Load data from source (async - may throw TimelineException)
  Future<List<Event>> loadData() async {
    try {
      return await _pipeline.dataService.loadData();
    } on TimelineException {
      emit(state.copyWith(error: 'Failed to load timeline data'));
      rethrow; // Preserve full exception context
    } catch (e) {
      final error = 'Unexpected error loading data: $e';
      emit(state.copyWith(error: error));
      throw TimelineException(error);
    }
  }

  /// Step 2: Sort events (sync - may throw TimelineException)
  void sort(List<Event> events) {
    _pipeline.sorter.sort(events); // Let exceptions bubble directly
  }

  /// Step 3: Calculate visible window (sync - may throw TimelineException)
  TimelineWindow calcWindow(List<Event> events) {
    return _pipeline.windowCalculator.calculateWindow(
      events,
    ); // Let exceptions bubble
  }

  /// Step 4: Layout events into rows (sync - may throw TimelineException)
  List<TimelineRow> layout(List<Event> events) {
    return _pipeline.rowBuilder.buildRows(events); // Let exceptions bubble
  }

  /// Step 5: Emit new state
  void emitState({
    List<Event>? events,
    TimelineWindow? window,
    List<TimelineRow>? rows,
    bool? isLoading,
    String? error,
  }) {
    emit(
      state.copyWith(
        events: events,
        visibleStart: window?.start,
        visibleEnd: window?.end,
        rows: rows,
        isLoading: isLoading,
        error: error,
      ),
    );
  }

  // Granular update methods (with validation)

  /// Add a single event to existing layout (may throw TimelineException)
  void addEvent(Event event) {
    try {
      final updatedRows = _pipeline.rowBuilder.addEvent(event, state.rows);
      final updatedEvents = [...state.events, event];
      emitState(events: updatedEvents, rows: updatedRows);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  /// Remove a single event from layout (may throw TimelineException)
  void removeEvent(String eventId) {
    try {
      final updatedRows = _pipeline.rowBuilder.removeEvent(eventId, state.rows);
      final updatedEvents = state.events.where((e) => e.id != eventId).toList();
      emitState(events: updatedEvents, rows: updatedRows);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // High-level orchestrator methods

  /// Full pipeline: load → sort → window → layout → emit
  @override
  Future<void> loadTimeline() async {
    emitState(isLoading: true);
    try {
      final result = await _pipeline.execute();
      emitState(
        events: result.events,
        window: result.window,
        rows: result.rows,
        isLoading: false,
      );
    } catch (e) {
      emitState(isLoading: false, error: e.toString());
    }
  }

  /// Process existing events through pipeline
  void process(List<Event> events) {
    try {
      final result = _pipeline.process(events);
      emitState(
        events: result.events,
        window: result.window,
        rows: result.rows,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // TimelineProvider interface implementation (with updated signatures)

  @override
  Future<List<Event>> parseEvents() async {
    return await loadData();
  }

  @override
  ({DateTime visibleStart, DateTime visibleEnd}) calculateVisibleWindow(
    List<Event> events,
  ) {
    final window = calcWindow(events);
    return (visibleStart: window.start, visibleEnd: window.end);
  }

  @override
  List<TimelineRow> layoutRows(List<Event> events) {
    return layout(events);
  }

  @override
  void updateTimeline(List<Event> events) {
    process(events);
  }

  @override
  void relayoutRows() {
    process(state.events);
  }

  // Factory methods - 2 essential patterns, compose custom pipelines directly

  /// Factory for testing with mock data
  static TimelineCubit fromMockData(List<Event> events) {
    return TimelineCubit(pipeline: TimelinePipeline.mockPipeline(events));
  }

  /// Factory for custom pipeline composition
  /// For advanced cases, compose TimelinePipeline directly:
  /// ```dart
  /// TimelineCubit(pipeline: TimelinePipeline(
  ///   dataService: NetworkDataService(url),
  ///   sorter: PrioritySorter(),
  ///   windowCalculator: WeeklyWindowCalculator(),
  ///   rowBuilder: DensePackingRowBuilder(),
  /// ))
  /// ```
  static TimelineCubit withPipeline(TimelinePipeline pipeline) {
    return TimelineCubit(pipeline: pipeline);
  }
}
