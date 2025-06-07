import 'package:equatable/equatable.dart';
import 'package:cross_platform_development/timeline/models/models.dart';

class TimelineState extends Equatable {
  const TimelineState({
    required this.visibleStart,
    required this.visibleEnd,
    this.events = const [],
    this.rows = const [],
    this.isLoading = false,
    this.error,
  });

  final DateTime visibleStart;
  final DateTime visibleEnd;
  final List<Event> events;
  final List<TimelineRow> rows;
  final bool isLoading;
  final String? error;

  TimelineState copyWith({
    DateTime? visibleStart,
    DateTime? visibleEnd,
    List<Event>? events,
    List<TimelineRow>? rows,
    bool? isLoading,
    String? error,
  }) {
    return TimelineState(
      visibleStart: visibleStart ?? this.visibleStart,
      visibleEnd: visibleEnd ?? this.visibleEnd,
      events: events ?? this.events,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Duration get visibleDuration => visibleEnd.difference(visibleStart);

  @override
  List<Object?> get props => [
    visibleStart,
    visibleEnd,
    events,
    rows,
    isLoading,
    error,
  ];
}

class TimelineRow extends Equatable {
  final int index;
  final List<Event> events;
  final double height;

  const TimelineRow({
    required this.index,
    required this.events,
    this.height = 60.0,
  });

  @override
  List<Object?> get props => [index, events, height];
}

/// Abstract interface for timeline data providers
/// This allows the UI to work with any implementation (Cubit, ChangeNotifier, etc.)
abstract class TimelineProvider {
  /// Current timeline state
  TimelineState get state;

  /// Stream of state changes
  Stream<TimelineState> get stream;

  /// Load timeline data
  Future<void> loadTimeline();

  /// Update timeline with new events
  void updateTimeline(List<Event> events);

  /// Relayout existing rows
  void relayoutRows();

  /// Parse events from data source
  Future<List<Event>> parseEvents();

  /// Calculate visible window for events
  ({DateTime visibleStart, DateTime visibleEnd}) calculateVisibleWindow(
    List<Event> events,
  );

  /// Layout events into rows
  List<TimelineRow> layoutRows(List<Event> events);
}
