
class NavigationState {
  final bool showTimeline;
  final bool showMap;

  NavigationState({
    required this.showTimeline,
    required this.showMap
  });

  NavigationState copyWith({
    bool? showTimeline,
    bool? showMap,
  }) {
    return NavigationState(
      showTimeline: showTimeline ?? this.showTimeline,
      showMap: showMap ?? this.showMap,
    );
  }
}
