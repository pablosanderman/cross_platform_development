import 'package:bloc/bloc.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'map_state.dart';

/// {@template map_cubit}
/// A [Cubit] which manages a [MapState] as its state.
/// Handles loading events with coordinates for map display.
/// {@endtemplate}
class MapCubit extends Cubit<MapState> {
  /// {@macro map_cubit}
  MapCubit({EventsRepository? eventsRepository})
    : _eventsRepository = eventsRepository ?? const EventsRepository(),
      super(const MapState());

  final EventsRepository _eventsRepository;

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
    emit(state.copyWith(selectedEvent: null));
  }
}
