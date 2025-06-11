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
    this.height = 75.0,
  });

  @override
  List<Object?> get props => [index, events, height];
}
