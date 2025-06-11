abstract class NavigationEvent {}

class PlaceHolder extends NavigationEvent {}

class ToggleTimeline extends NavigationEvent {
  final bool forceNavigate;

  ToggleTimeline({this.forceNavigate = false});
}

class ToggleMap extends NavigationEvent {
  final bool forceNavigate;

  ToggleMap({this.forceNavigate = false});
}

class ChangePage extends NavigationEvent {
  final int pageIndex;

  ChangePage(this.pageIndex);
}
