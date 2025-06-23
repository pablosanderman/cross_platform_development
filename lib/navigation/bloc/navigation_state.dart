class NavigationState {
  final bool showTimeline;
  final bool showMap;
  final int currentPageIndex;
  final double splitRatio; // 0.0 = full map, 1.0 = full timeline, 0.5 = equal split

  NavigationState({
    required this.showTimeline,
    required this.showMap,
    required this.currentPageIndex,
    this.splitRatio = 0.5, // Default to equal split
  });

  NavigationState copyWith({
    bool? showTimeline,
    bool? showMap,
    int? currentPageIndex,
    double? splitRatio,
  }) {
    return NavigationState(
      showTimeline: showTimeline ?? this.showTimeline,
      showMap: showMap ?? this.showMap,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      splitRatio: splitRatio ?? this.splitRatio,
    );
  }
}
