import 'package:equatable/equatable.dart';
import 'package:cross_platform_development/shared/shared.dart';

/// {@template map_state}
/// Represents the state of the map feature.
/// {@endtemplate}
class MapState extends Equatable {
  /// {@macro map_state}
  const MapState({
    this.status = MapStatus.initial,
    this.events = const <Event>[],
    this.selectedEvent,
    this.popupEvents = const <Event>[],
    this.popupCurrentIndex = 0,
    this.showPopup = false,
  });

  /// The loading status of the map
  final MapStatus status;

  /// List of events that have coordinates (for display on map)
  final List<Event> events;

  /// Currently selected event (if any)
  final Event? selectedEvent;

  /// List of events to show in popup (single event or cluster)
  final List<Event> popupEvents;

  /// Current index in popup events (for navigation)
  final int popupCurrentIndex;

  /// Whether to show the popup
  final bool showPopup;

  /// Copy with method for state updates
  MapState copyWith({
    MapStatus? status,
    List<Event>? events,
    Event? selectedEvent,
    List<Event>? popupEvents,
    int? popupCurrentIndex,
    bool? showPopup,
  }) {
    return MapState(
      status: status ?? this.status,
      events: events ?? this.events,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      popupEvents: popupEvents ?? this.popupEvents,
      popupCurrentIndex: popupCurrentIndex ?? this.popupCurrentIndex,
      showPopup: showPopup ?? this.showPopup,
    );
  }

  @override
  List<Object?> get props => [
    status,
    events,
    selectedEvent,
    popupEvents,
    popupCurrentIndex,
    showPopup,
  ];
}

/// Enum representing the loading status of map data
enum MapStatus {
  /// Initial state
  initial,

  /// Currently loading events
  loading,

  /// Events loaded successfully
  loaded,

  /// Error loading events
  error,
}
