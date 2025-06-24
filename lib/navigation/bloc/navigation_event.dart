import 'package:cross_platform_development/shared/models/event.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_state.dart';

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

// Event details navigation events
class ShowEventDetails extends NavigationEvent {
  final Event event;
  final EventDetailsSource source;

  ShowEventDetails(this.event, this.source) : super(forceNavigate: true);
}

class CloseEventDetails extends NavigationEvent {
  CloseEventDetails() : super(forceNavigate: false);
}

class SwitchEventDetailsView extends NavigationEvent {
  final EventDetailsSource targetSource;

  SwitchEventDetailsView(this.targetSource) : super(forceNavigate: false);
}

class UpdateSplitRatio extends NavigationEvent {
  final double splitRatio;
  UpdateSplitRatio(this.splitRatio) : super(forceNavigate: false);
}

class UpdateEventDetailsSplitRatio extends NavigationEvent {
  final double splitRatio;
  UpdateEventDetailsSplitRatio(this.splitRatio) : super(forceNavigate: false);
}
