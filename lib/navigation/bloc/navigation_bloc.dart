import 'package:cross_platform_development/navigation/bloc/navigation_event.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
    : super(NavigationState(showTimeline: true, showMap: false)) {
    on<ToggleTimeline>((event, emit) {
      final newtimelineState = !state.showTimeline;

      if (!newtimelineState && !state.showMap) {
        return;
      }

      emit(state.copyWith(showTimeline: newtimelineState));
    });

    on<ToggleMap>((event, emit) {
      final newMapState = !state.showMap;

      if (!newMapState && !state.showTimeline) {
        return;
      }

      emit(state.copyWith(showMap: newMapState));
    });

    on<ShowMap>((event, emit) {
      // Always show the map, don't toggle
      emit(state.copyWith(showMap: true));
    });

    on<ShowTimeline>((event, emit) {
      // Always show the timeline, don't toggle
      emit(state.copyWith(showTimeline: true));
    });
  }
}
