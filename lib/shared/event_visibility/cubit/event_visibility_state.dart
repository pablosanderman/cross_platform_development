part of 'event_visibility_cubit.dart';

/// {@template event_visibility_state}
/// State for the [EventVisibilityCubit].
/// Contains the set of hidden event IDs and panel open state.
/// {@endtemplate}
class EventVisibilityState extends Equatable {
  /// {@macro event_visibility_state}
  const EventVisibilityState({
    this.hiddenIds = const <String>{},
    this.panelOpen = false,
  });

  /// Set of event IDs that are currently hidden
  final Set<String> hiddenIds;

  /// Whether the visibility panel is currently open
  final bool panelOpen;

  /// Create a copy of this state with optional parameter overrides
  EventVisibilityState copyWith({
    Set<String>? hiddenIds,
    bool? panelOpen,
  }) {
    return EventVisibilityState(
      hiddenIds: hiddenIds ?? this.hiddenIds,
      panelOpen: panelOpen ?? this.panelOpen,
    );
  }

  @override
  List<Object> get props => [hiddenIds, panelOpen];
}