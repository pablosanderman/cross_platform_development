import 'package:cross_platform_development/navigation/bloc/navigation_event.dart';
import 'package:cross_platform_development/navigation/bloc/navigation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
    : super(
        NavigationState(
          showTimeline: true,
          showMap: false,
          currentPageIndex: 0,
        ),
      ) {
    on<ToggleTimeline>(_handleToggleTimeline);
    on<ToggleMap>(_handleToggleMap);
    on<ChangePage>(_handleChangePage);
    on<ShowMap>(_handleShowMap);
    on<ShowTimeline>(_handleShowTimeline);
  }

  void _handleToggleTimeline(
    ToggleTimeline event,
    Emitter<NavigationState> emit,
  ) {
    final newtimelineState = !state.showTimeline;
    if (!newtimelineState && !state.showMap) {
      return;
    }

    if (state.currentPageIndex != 0 || event.forceNavigate) {
      emit(state.copyWith(showTimeline: true, currentPageIndex: 0));
    } else {
      emit(state.copyWith(showTimeline: !state.showTimeline));
    }
  }

  void _handleToggleMap(ToggleMap event, Emitter<NavigationState> emit) {
    final newMapState = !state.showMap;
    if (!newMapState && !state.showTimeline) {
      return;
    }

    if (state.currentPageIndex != 0 || event.forceNavigate) {
      emit(state.copyWith(showMap: true, currentPageIndex: 0));
    } else {
      emit(state.copyWith(showMap: !state.showMap));
    }
  }

  void _handleChangePage(ChangePage event, Emitter<NavigationState> emit) {
    print("Changing page index to: ${event.pageIndex}");
    emit(
      state.copyWith(
        showTimeline: false,
        showMap: false,
        currentPageIndex: event.pageIndex,
      ),
    );
  }

  void _handleShowMap(ShowMap event, Emitter<NavigationState> emit) {
    // Navigate to timeline/map page (index 0) and ensure map is visible
    emit(state.copyWith(showMap: true, currentPageIndex: 0));
  }

  void _handleShowTimeline(ShowTimeline event, Emitter<NavigationState> emit) {
    // Navigate to timeline/map page (index 0) and ensure timeline is visible
    emit(state.copyWith(showTimeline: true, currentPageIndex: 0));
  }
}
