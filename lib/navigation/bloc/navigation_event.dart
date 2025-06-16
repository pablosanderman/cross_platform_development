abstract class NavigationEvent {}

class PlaceHolder extends NavigationEvent {}

class ToggleTimeline
    extends NavigationEvent {} // These will be used to toggle the map/timeline

class ToggleMap extends NavigationEvent {}

class ShowMap extends NavigationEvent {} // Ensure map is shown without toggling

class ShowTimeline
    extends NavigationEvent {} // Ensure timeline is shown without toggling
