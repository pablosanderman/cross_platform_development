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
    this.highlightedEvent,
    this.centerOnEvent,
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

  /// Event highlighted from timeline hover (if any)
  final Event? highlightedEvent;

  /// Event to center map on (triggered from "View on Map" button)
  final Event? centerOnEvent;

  /// Copy with method for state updates
  MapState copyWith({
    MapStatus? status,
    List<Event>? events,
    Event? selectedEvent,
    List<Event>? popupEvents,
    int? popupCurrentIndex,
    bool? showPopup,
    Event? highlightedEvent,
    Event? centerOnEvent,
    bool clearCenterOnEvent = false,
  }) {
    return MapState(
      status: status ?? this.status,
      events: events ?? this.events,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      popupEvents: popupEvents ?? this.popupEvents,
      popupCurrentIndex: popupCurrentIndex ?? this.popupCurrentIndex,
      showPopup: showPopup ?? this.showPopup,
      highlightedEvent: highlightedEvent ?? this.highlightedEvent,
      centerOnEvent: clearCenterOnEvent
          ? null
          : (centerOnEvent ?? this.centerOnEvent),
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
    highlightedEvent,
    centerOnEvent,
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
