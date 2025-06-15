import 'package:cross_platform_development/navigation/bloc/navigation_event.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
      : super(NavigationState(
      showTimeline: true,
      showMap: false,
      currentPageIndex: 0)) {
    on<ToggleTimeline>(_handleToggleTimeline);
    on<ToggleMap>(_handleToggleMap);
    on<ChangePage>(_handleChangePage);
  }

  void _handleToggleTimeline(
    ToggleTimeline event,
    Emitter<NavigationState> emit,
    ) {
    final newtimelineState = !state.showTimeline;
    if(!newtimelineState && !state.showMap) { return; }

    if (state.currentPageIndex != 0 || event.forceNavigate) {
      emit(state.copyWith(showTimeline: true, currentPageIndex: 0));
    } else {
      emit(state.copyWith(showTimeline: !state.showTimeline));
    }
  }

  void _handleToggleMap(
      ToggleMap event,
      Emitter<NavigationState> emit,
      ) {
    final newMapState = !state.showMap;
    if (!newMapState && !state.showTimeline) { return; }

    if (state.currentPageIndex != 0 || event.forceNavigate) {
      emit(state.copyWith(showMap: true,currentPageIndex: 0));
    } else {
      emit(state.copyWith(showMap: !state.showMap));
    }
  }

  void _handleChangePage(
      ChangePage event,
      Emitter<NavigationState> emit,
      ) {
    emit(state.copyWith(
        showTimeline: false,
        showMap: false,
        currentPageIndex: event.pageIndex));
  }
}
