import 'package:bloc/bloc.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'map_state.dart';

/// {@template map_cubit}
/// A [Cubit] which manages a [MapState] as its state.
/// Handles loading events with coordinates for map display.
/// {@endtemplate}
class MapCubit extends Cubit<MapState> {
  /// {@macro map_cubit}
  MapCubit({
    EventsRepository? eventsRepository,
    NavigationBloc? navigationBloc,
    TimelineCubit? timelineCubit,
  }) : _eventsRepository = eventsRepository ?? const EventsRepository(),
       _navigationBloc = navigationBloc,
       _timelineCubit = timelineCubit,
       super(const MapState());

  final EventsRepository _eventsRepository;
  final NavigationBloc? _navigationBloc;
  final TimelineCubit? _timelineCubit;

  /// Load events that have geographic coordinates
  Future<void> loadMapEvents() async {
    try {
      emit(state.copyWith(status: MapStatus.loading));

      final events = await _eventsRepository.loadEventsWithCoordinates();

      emit(state.copyWith(status: MapStatus.loaded, events: events));
    } catch (error) {
      emit(state.copyWith(status: MapStatus.error));
    }
  }

  /// Select an event (for highlighting on map)
  void selectEvent(Event? event) {
    emit(state.copyWith(selectedEvent: event));
  }

  /// Clear event selection
  void clearSelection() {
    emit(state.copyWith(clearSelectedEvent: true));
  }

  /// Show popup for a single event
  void showEventPopup(Event event) {
    // Select the event using shared selection state
    _timelineCubit?.selectEvent(event);

    emit(
      state.copyWith(
        popupEvents: [event],
        popupCurrentIndex: 0,
        showPopup: true,
      ),
    );
  }

  /// Show popup for multiple events (cluster)
  void showClusterPopup(List<Event> events) {
    // Select the first event using shared selection state
    _timelineCubit?.selectEvent(events.first);

    emit(
      state.copyWith(
        popupEvents: events,
        popupCurrentIndex: 0,
        showPopup: true,
      ),
    );
  }

  /// Navigate to next event in popup
  void nextPopupEvent() {
    if (state.popupEvents.isEmpty) return;

    final nextIndex = (state.popupCurrentIndex + 1) % state.popupEvents.length;
    final nextEvent = state.popupEvents[nextIndex];

    // Select the next event using shared selection state
    _timelineCubit?.selectEvent(nextEvent);

    emit(state.copyWith(popupCurrentIndex: nextIndex));
  }

  /// Navigate to previous event in popup
  void previousPopupEvent() {
    if (state.popupEvents.isEmpty) return;

    final prevIndex = state.popupCurrentIndex == 0
        ? state.popupEvents.length - 1
        : state.popupCurrentIndex - 1;
    final prevEvent = state.popupEvents[prevIndex];

    // Select the previous event using shared selection state
    _timelineCubit?.selectEvent(prevEvent);

    emit(state.copyWith(popupCurrentIndex: prevIndex));
  }

  /// Close popup
  void closePopup() {
    // Clear selection using shared selection state
    _timelineCubit?.clearSelection();

    emit(
      state.copyWith(
        showPopup: false,
        popupEvents: <Event>[],
        popupCurrentIndex: 0,
      ),
    );
  }

  /// Highlight event from timeline hover
  void highlightEvent(Event? event) {
    emit(state.copyWith(highlightedEvent: event));
  }

  /// Clear event highlight
  void clearHighlight() {
    emit(state.copyWith(clearHighlightedEvent: true));
  }

  /// Navigate to event on map (center map and show popup)
  void navigateToEvent(Event event) {
    // Ensure map view is visible
    _navigationBloc?.add(ShowMap());

    // First select and show popup for the event
    showEventPopup(event);

    // Emit a special state that indicates map should center on this event
    emit(state.copyWith(centerOnEvent: event));
  }

  /// Clear the center on event flag (called after map has centered)
  void clearCenterOnEvent() {
    emit(state.copyWith(clearCenterOnEvent: true));
  }

  /// Navigate to event on timeline (scroll timeline and show timeline view)
  void navigateToTimeline(Event event) {
    // Ensure timeline view is visible
    _navigationBloc?.add(ShowTimeline());

    // Scroll timeline to show the event
    _timelineCubit?.scrollToEvent(event);
  }

  /// Handle map marker hover - highlight event on timeline
  void hoverMapEvent(Event event) {
    _timelineCubit?.setHoveredEvent(event);
  }

  /// Handle map marker hover exit - clear timeline highlight
  void exitMapEventHover() {
    _timelineCubit?.clearHoveredEvent();
  }

  /// Update selected event from timeline (for shared selection state)
  void updateSelectedEvent(Event? event) {
    emit(
      state.copyWith(selectedEvent: event, clearSelectedEvent: event == null),
    );
  }
}
