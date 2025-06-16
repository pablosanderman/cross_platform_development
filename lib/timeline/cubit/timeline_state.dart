import 'package:equatable/equatable.dart';
import 'package:cross_platform_development/shared/shared.dart';

class TimelineState extends Equatable {
  const TimelineState({
    required this.visibleStart,
    required this.visibleEnd,
    this.events = const [],
    this.rows = const [],
    this.isLoading = false,
    this.error,
    this.hoveredEvent,
    this.selectedEvent,
    this.scrollToEvent,
  });

  final DateTime visibleStart;
  final DateTime visibleEnd;
  final List<Event> events;
  final List<TimelineRow> rows;
  final bool isLoading;
  final String? error;
  final Event? hoveredEvent;
  final Event? selectedEvent;

  /// Event to scroll to - triggers programmatic scrolling in the view
  final Event? scrollToEvent;

  TimelineState copyWith({
    DateTime? visibleStart,
    DateTime? visibleEnd,
    List<Event>? events,
    List<TimelineRow>? rows,
    bool? isLoading,
    String? error,
    Event? hoveredEvent,
    bool clearHoveredEvent = false,
    Event? selectedEvent,
    bool clearSelectedEvent = false,
    Event? scrollToEvent,
    bool clearScrollToEvent = false,
  }) {
    return TimelineState(
      visibleStart: visibleStart ?? this.visibleStart,
      visibleEnd: visibleEnd ?? this.visibleEnd,
      events: events ?? this.events,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hoveredEvent: clearHoveredEvent
          ? null
          : (hoveredEvent ?? this.hoveredEvent),
      selectedEvent: clearSelectedEvent
          ? null
          : (selectedEvent ?? this.selectedEvent),
      scrollToEvent: clearScrollToEvent
          ? null
          : (scrollToEvent ?? this.scrollToEvent),
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
    hoveredEvent,
    selectedEvent,
    scrollToEvent,
  ];
}

class TimelineRow extends Equatable {
  final int index;
  final List<Event> events;
  final double height;

  const TimelineRow({
    required this.index,
    required this.events,
    this.height = 75.0,
  });

  @override
  List<Object?> get props => [index, events, height];
}
