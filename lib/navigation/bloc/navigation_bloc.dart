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
    on<ShowEventDetails>(_handleShowEventDetails);
    on<CloseEventDetails>(_handleCloseEventDetails);
    on<SwitchEventDetailsView>(_handleSwitchEventDetailsView);
    on<UpdateSplitRatio>(_handleUpdateSplitRatio);
    on<UpdateEventDetailsSplitRatio>(_handleUpdateEventDetailsSplitRatio);
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

  void _handleShowEventDetails(
    ShowEventDetails event,
    Emitter<NavigationState> emit,
  ) {
    // Navigate to timeline/map page (index 0) and show event details as overlay

    // Store current state to restore when closing details
    final previousShowTimeline = state.showTimeline;
    final previousShowMap = state.showMap;

    // Force split-screen mode when showing event details
    emit(
      state.copyWith(
        showTimeline: true,
        showMap: true,
        currentPageIndex: 0,
        selectedEventForDetails: event.event,
        detailsSource: event.source,
        previousShowTimeline: previousShowTimeline,
        previousShowMap: previousShowMap,
      ),
    );
  }

  void _handleCloseEventDetails(
    CloseEventDetails event,
    Emitter<NavigationState> emit,
  ) {
    // Restore the previous view state
    final previousTimeline = state.previousShowTimeline ?? true;
    final previousMap = state.previousShowMap ?? false;

    emit(
      state.copyWith(
        showTimeline: previousTimeline,
        showMap: previousMap,
        clearEventDetails: true,
      ),
    );
  }

  void _handleSwitchEventDetailsView(
    SwitchEventDetailsView event,
    Emitter<NavigationState> emit,
  ) {
    // Switch the overlay position while maintaining event details and both views visible
    emit(state.copyWith(detailsSource: event.targetSource));
  }

  void _handleUpdateSplitRatio(
    UpdateSplitRatio event,
    Emitter<NavigationState> emit,
  ) {
    // Clamp split ratio between 0.0 and 1.0
    final clampedRatio = event.splitRatio.clamp(0.0, 1.0);
    emit(state.copyWith(splitRatio: clampedRatio));
  }

  void _handleUpdateEventDetailsSplitRatio(
    UpdateEventDetailsSplitRatio event,
    Emitter<NavigationState> emit,
  ) {
    // Clamp split ratio between 0.0 and 1.0
    final clampedRatio = event.splitRatio.clamp(0.0, 1.0);
    emit(state.copyWith(eventDetailsSplitRatio: clampedRatio));
  }
}
