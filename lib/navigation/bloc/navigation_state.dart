import 'package:cross_platform_development/shared/models/event_v2.dart';

enum EventDetailsSource { timeline, map }

class NavigationState {
  final bool showTimeline;
  final bool showMap;
  final int currentPageIndex;
  final Event? selectedEventForDetails;
  final EventDetailsSource? detailsSource;

  // Store the previous state before showing event details
  final bool? previousShowTimeline;
  final bool? previousShowMap;
  final double
  splitRatio; // 0.0 = full map, 1.0 = full timeline, 0.5 = equal split
  final double
  eventDetailsSplitRatio; // For event details overlay: 0.0 = minimal details, 1.0 = maximal details, 0.5 = equal split
  final double?
  mobileSplitRatio; // For mobile vertical split: 0.0 = full timeline, 1.0 = full map, 0.4 = default (40% map, 60% timeline)

  NavigationState({
    required this.showTimeline,
    required this.showMap,
    required this.currentPageIndex,
    this.selectedEventForDetails,
    this.detailsSource,
    this.previousShowTimeline,
    this.previousShowMap,
    this.splitRatio = 0.5, // Default to equal split
    this.eventDetailsSplitRatio =
        0.5, // Default to equal split for event details
    this.mobileSplitRatio, // Default null, will use 0.4 if not set
  });

  /// Checks if event details panel should be shown
  bool get showEventDetails => selectedEventForDetails != null;

  /// Checks if we're in split-screen mode with event details
  bool get isInEventDetailsMode => showEventDetails;

  NavigationState copyWith({
    bool? showTimeline,
    bool? showMap,
    int? currentPageIndex,
    Event? selectedEventForDetails,
    EventDetailsSource? detailsSource,
    bool? previousShowTimeline,
    bool? previousShowMap,
    bool clearEventDetails = false,
    double? splitRatio,
    double? eventDetailsSplitRatio,
    double? mobileSplitRatio,
  }) {
    return NavigationState(
      showTimeline: showTimeline ?? this.showTimeline,
      showMap: showMap ?? this.showMap,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      selectedEventForDetails: clearEventDetails
          ? null
          : (selectedEventForDetails ?? this.selectedEventForDetails),
      detailsSource: clearEventDetails
          ? null
          : (detailsSource ?? this.detailsSource),
      previousShowTimeline: clearEventDetails
          ? null
          : (previousShowTimeline ?? this.previousShowTimeline),
      previousShowMap: clearEventDetails
          ? null
          : (previousShowMap ?? this.previousShowMap),
      splitRatio: splitRatio ?? this.splitRatio,
      eventDetailsSplitRatio:
          eventDetailsSplitRatio ?? this.eventDetailsSplitRatio,
      mobileSplitRatio: mobileSplitRatio ?? this.mobileSplitRatio,
    );
  }
}
