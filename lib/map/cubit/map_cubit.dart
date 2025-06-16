import 'package:bloc/bloc.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'map_state.dart';

/// {@template map_cubit}
/// A [Cubit] which manages a [MapState] as its state.
/// Handles loading events with coordinates for map display.
/// {@endtemplate}
class MapCubit extends Cubit<MapState> {
  /// {@macro map_cubit}
  MapCubit({EventsRepository? eventsRepository, NavigationBloc? navigationBloc})
    : _eventsRepository = eventsRepository ?? const EventsRepository(),
      _navigationBloc = navigationBloc,
      super(const MapState());

  final EventsRepository _eventsRepository;
  final NavigationBloc? _navigationBloc;

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
    emit(
      state.copyWith(
        popupEvents: [event],
        popupCurrentIndex: 0,
        showPopup: true,
        selectedEvent: event,
      ),
    );
  }

  /// Show popup for multiple events (cluster)
  void showClusterPopup(List<Event> events) {
    emit(
      state.copyWith(
        popupEvents: events,
        popupCurrentIndex: 0,
        showPopup: true,
        selectedEvent: events.first,
      ),
    );
  }

  /// Navigate to next event in popup
  void nextPopupEvent() {
    if (state.popupEvents.isEmpty) return;

    final nextIndex = (state.popupCurrentIndex + 1) % state.popupEvents.length;
    emit(
      state.copyWith(
        popupCurrentIndex: nextIndex,
        selectedEvent: state.popupEvents[nextIndex],
      ),
    );
  }

  /// Navigate to previous event in popup
  void previousPopupEvent() {
    if (state.popupEvents.isEmpty) return;

    final prevIndex = state.popupCurrentIndex == 0
        ? state.popupEvents.length - 1
        : state.popupCurrentIndex - 1;
    emit(
      state.copyWith(
        popupCurrentIndex: prevIndex,
        selectedEvent: state.popupEvents[prevIndex],
      ),
    );
  }

  /// Close popup
  void closePopup() {
    emit(
      state.copyWith(
        showPopup: false,
        popupEvents: <Event>[],
        popupCurrentIndex: 0,
        clearSelectedEvent: true,
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
    // Ensure map view is visible (don't toggle, always show)
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
}
