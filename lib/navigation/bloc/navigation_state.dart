import 'package:cross_platform_development/shared/models/event.dart';

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
  final double splitRatio; // 0.0 = full map, 1.0 = full timeline, 0.5 = equal split

  NavigationState({
    required this.showTimeline,
    required this.showMap,
    required this.currentPageIndex,
    this.selectedEventForDetails,
    this.detailsSource,
    this.previousShowTimeline,
    this.previousShowMap,
    this.splitRatio = 0.5, // Default to equal split
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
  }) {
    return NavigationState(
      showTimeline: showTimeline ?? this.showTimeline,
      showMap: showMap ?? this.showMap,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      selectedEventForDetails: clearEventDetails ? null : (selectedEventForDetails ?? this.selectedEventForDetails),
      detailsSource: clearEventDetails ? null : (detailsSource ?? this.detailsSource),
      previousShowTimeline: clearEventDetails ? null : (previousShowTimeline ?? this.previousShowTimeline),
      previousShowMap: clearEventDetails ? null : (previousShowMap ?? this.previousShowMap),
      splitRatio: splitRatio ?? this.splitRatio,
    );
  }
}
