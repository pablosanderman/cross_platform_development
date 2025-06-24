import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'event_visibility_state.dart';

/// {@template event_visibility_cubit}
/// A [Cubit] which manages the visibility state of events.
/// Controls which events are hidden and whether the visibility panel is open.
/// {@endtemplate}
class EventVisibilityCubit extends Cubit<EventVisibilityState> {
  /// {@macro event_visibility_cubit}
  EventVisibilityCubit() : super(const EventVisibilityState());

  /// Toggle the visibility of an event by its ID
  void toggle(String eventId) {
    final hiddenIds = Set<String>.from(state.hiddenIds);
    
    if (hiddenIds.contains(eventId)) {
      hiddenIds.remove(eventId);
    } else {
      hiddenIds.add(eventId);
    }
    
    emit(state.copyWith(hiddenIds: hiddenIds));
  }

  /// Toggle the visibility panel open/closed state
  void togglePanel() {
    emit(state.copyWith(panelOpen: !state.panelOpen));
  }

  /// Close the visibility panel
  void closePanel() {
    emit(state.copyWith(panelOpen: false));
  }

  /// Check if an event is hidden
  bool isHidden(String eventId) {
    return state.hiddenIds.contains(eventId);
  }

  /// Show all events (clear all hidden events)
  void showAll() {
    emit(state.copyWith(hiddenIds: const <String>{}));
  }

  /// Hide all events
  void hideAll(Set<String> allEventIds) {
    emit(state.copyWith(hiddenIds: allEventIds));
  }
}