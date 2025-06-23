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

  void _handleShowEventDetails(ShowEventDetails event, Emitter<NavigationState> emit) {
    // Navigate to timeline/map page (index 0) and show event details
    
    // Determine current view state to handle transitions properly
    final currentlyBothVisible = state.showTimeline && state.showMap;
    final currentlyTimelineOnly = state.showTimeline && !state.showMap;
    final currentlyMapOnly = !state.showTimeline && state.showMap;
    
    if (event.source == EventDetailsSource.timeline) {
      // Timeline click: Show timeline + event details (replace map)
      // If currently in full-screen timeline, transition to split view
      // If currently in split view or map-only, show timeline + details
      emit(state.copyWith(
        showTimeline: true,
        showMap: false,
        currentPageIndex: 0,
        selectedEventForDetails: event.event,
        detailsSource: EventDetailsSource.timeline,
      ));
    } else {
      // Map click: Show event details + map (replace timeline)  
      // If currently in full-screen map, transition to split view
      // If currently in split view or timeline-only, show details + map
      emit(state.copyWith(
        showTimeline: false,
        showMap: true,
        currentPageIndex: 0,
        selectedEventForDetails: event.event,
        detailsSource: EventDetailsSource.map,
      ));
    }
  }

  void _handleCloseEventDetails(CloseEventDetails event, Emitter<NavigationState> emit) {
    // Return to the previous view state based on the details source
    if (state.detailsSource == EventDetailsSource.timeline) {
      // Return to timeline view
      emit(state.copyWith(
        showTimeline: true,
        showMap: false,
        clearEventDetails: true,
      ));
    } else {
      // Return to map view
      emit(state.copyWith(
        showTimeline: false,
        showMap: true,
        clearEventDetails: true,
      ));
    }
  }

  void _handleSwitchEventDetailsView(SwitchEventDetailsView event, Emitter<NavigationState> emit) {
    // Switch to the target view while maintaining event details
    if (event.targetSource == EventDetailsSource.timeline) {
      // Switch to timeline + event details
      emit(state.copyWith(
        showTimeline: true,
        showMap: false,
        detailsSource: EventDetailsSource.timeline,
      ));
    } else {
      // Switch to map + event details
      emit(state.copyWith(
        showTimeline: false,
        showMap: true,
        detailsSource: EventDetailsSource.map,
      ));
    }
  }
}
