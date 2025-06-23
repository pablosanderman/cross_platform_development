abstract class NavigationEvent {
  final bool forceNavigate;
  NavigationEvent({this.forceNavigate = false});
}

class PlaceHolder extends NavigationEvent {
  PlaceHolder() : super(forceNavigate: false);
}

class ToggleTimeline extends NavigationEvent {
  ToggleTimeline({super.forceNavigate});
}

class ToggleMap extends NavigationEvent {
  ToggleMap({super.forceNavigate});
}

class ChangePage extends NavigationEvent {
  final int pageIndex;
  ChangePage(this.pageIndex) : super(forceNavigate: true);
}

// Additional events for explicit timeline/map showing
class ShowMap extends NavigationEvent {
  ShowMap() : super(forceNavigate: true);
}

class ShowTimeline extends NavigationEvent {
  ShowTimeline() : super(forceNavigate: true);
}
