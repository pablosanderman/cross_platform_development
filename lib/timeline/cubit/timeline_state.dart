import 'package:equatable/equatable.dart';
import 'package:cross_platform_development/timeline/models/models.dart';

class TimelineState extends Equatable {
  const TimelineState({
    this.events = const [],
    required this.visibleStart,
    required this.visibleEnd,
    this.zoomLevel = 100.0, // Default: 100 pixels per hour
    this.panOffset = 0.0,
    this.isLoading = false,
    this.error,
    this.rows = const [],
  });

  final List<Event> events;
  final DateTime visibleStart;
  final DateTime visibleEnd;
  final double zoomLevel; // pixels per hour
  final double panOffset; // horizontal offset in pixels
  final bool isLoading;
  final String? error;
  final List<TimelineRow> rows;

  TimelineState copyWith({
    List<Event>? events,
    DateTime? visibleStart,
    DateTime? visibleEnd,
    double? zoomLevel,
    double? panOffset,
    bool? isLoading,
    String? error,
    List<TimelineRow>? rows,
  }) {
    return TimelineState(
      events: events ?? this.events,
      visibleStart: visibleStart ?? this.visibleStart,
      visibleEnd: visibleEnd ?? this.visibleEnd,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rows: rows ?? this.rows,
    );
  }

  Duration get visibleDuration => visibleEnd.difference(visibleStart);

  double get totalWidth => visibleDuration.inHours * zoomLevel;

  @override
  List<Object?> get props => [
    events,
    visibleStart,
    visibleEnd,
    zoomLevel,
    panOffset,
    isLoading,
    error,
    rows,
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
