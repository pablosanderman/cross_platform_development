class NavigationState {
  final bool showTimeline;
  final bool showMap;
  final int currentPageIndex;

  NavigationState({
    required this.showTimeline,
    required this.showMap,
    required this.currentPageIndex,
  });

  NavigationState copyWith({
    bool? showTimeline,
    bool? showMap,
    int? currentPageIndex,
  }) {
    return NavigationState(
      showTimeline: showTimeline ?? this.showTimeline,
      showMap: showMap ?? this.showMap,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }
}
