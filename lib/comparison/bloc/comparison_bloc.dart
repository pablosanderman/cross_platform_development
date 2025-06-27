import 'package:flutter_bloc/flutter_bloc.dart';
import 'comparison_event.dart';
import 'comparison_state.dart';
import '../models/models.dart';
import '../../shared/repositories/repositories.dart';

class ComparisonBloc extends Bloc<ComparisonEvent, ComparisonState> {
  final EventsRepository _eventsRepository;
  final RecentlyViewedService _recentlyViewedService;
  
  ComparisonBloc({
    required EventsRepository eventsRepository,
    required RecentlyViewedService recentlyViewedService,
  }) : _eventsRepository = eventsRepository,
       _recentlyViewedService = recentlyViewedService,
       super(const ComparisonState()) {
    
    on<AddEventToComparison>(_onAddEventToComparison);
    on<RemoveEventFromComparison>(_onRemoveEventFromComparison);
    on<ClearComparisonList>(_onClearComparisonList);
    on<ToggleComparisonListVisibility>(_onToggleComparisonListVisibility);
    on<ShowComparisonSelectionOverlay>(_onShowComparisonSelectionOverlay);
    on<HideComparisonSelectionOverlay>(_onHideComparisonSelectionOverlay);
    on<NavigateToComparisonResults>(_onNavigateToComparisonResults);
    on<SearchEventsForComparison>(_onSearchEventsForComparison);
    on<LoadEventsForComparison>(_onLoadEventsForComparison);
    on<MarkEventAsViewed>(_onMarkEventAsViewed);
    
    // Initialize the service
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _recentlyViewedService.loadFromStorage();
    add(const LoadEventsForComparison());
  }
  
  void _onAddEventToComparison(
    AddEventToComparison event,
    Emitter<ComparisonState> emit,
  ) {
    // Check if already at max capacity
    if (state.isAtMaxCapacity) {
      emit(state.copyWith(
        errorMessage: 'Maximum ${ComparisonState.maxComparisonItems} events can be compared',
      ));
      return;
    }
    
    // Check if event is already in comparison
    if (state.isEventInComparison(event.event.id)) {
      emit(state.copyWith(
        errorMessage: 'Event is already in comparison list',
      ));
      return;
    }
    
    final newItem = ComparisonEventItem(
      event: event.event,
      addedAt: DateTime.now(),
    );
    
    final updatedList = [...state.comparisonList, newItem];
    
    emit(state.copyWith(
      comparisonList: updatedList,
      errorMessage: null,
    ));
  }
  
  void _onRemoveEventFromComparison(
    RemoveEventFromComparison event,
    Emitter<ComparisonState> emit,
  ) {
    final updatedList = state.comparisonList
        .where((item) => item.event.id != event.eventId)
        .toList();
    
    emit(state.copyWith(
      comparisonList: updatedList,
      errorMessage: null,
    ));
  }
  
  void _onClearComparisonList(
    ClearComparisonList event,
    Emitter<ComparisonState> emit,
  ) {
    emit(state.copyWith(
      comparisonList: [],
      errorMessage: null,
    ));
  }
  
  void _onToggleComparisonListVisibility(
    ToggleComparisonListVisibility event,
    Emitter<ComparisonState> emit,
  ) {
    emit(state.copyWith(
      isFloatingListVisible: !state.isFloatingListVisible,
    ));
  }
  
  void _onShowComparisonSelectionOverlay(
    ShowComparisonSelectionOverlay event,
    Emitter<ComparisonState> emit,
  ) {
    emit(state.copyWith(
      isSelectionOverlayVisible: true,
      searchQuery: '',
      searchResults: [],
      recentlyViewedEvents: _recentlyViewedService.recentEvents,
    ));
    
    // Ensure events are loaded when overlay is shown
    if (state.allEvents.isEmpty) {
      add(const LoadEventsForComparison());
    }
  }
  
  void _onHideComparisonSelectionOverlay(
    HideComparisonSelectionOverlay event,
    Emitter<ComparisonState> emit,
  ) {
    emit(state.copyWith(
      isSelectionOverlayVisible: false,
      searchQuery: '',
      searchResults: [],
    ));
  }
  
  void _onNavigateToComparisonResults(
    NavigateToComparisonResults event,
    Emitter<ComparisonState> emit,
  ) {
    // This will be handled by the navigation system
    // The BLoC just needs to ensure the comparison list is ready
    if (!state.canCompare) {
      emit(state.copyWith(
        errorMessage: 'At least 2 events are required for comparison',
      ));
    }
  }
  
  void _onSearchEventsForComparison(
    SearchEventsForComparison event,
    Emitter<ComparisonState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    
    // If query is empty, just clear results
    if (query.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        searchResults: [],
      ));
      return;
    }
    
    // If allEvents is empty, try to load them first then search
    if (state.allEvents.isEmpty) {
      emit(state.copyWith(searchQuery: query)); // Update query first
      add(const LoadEventsForComparison());
      return;
    }
    
    // Filter events based on search query
    final results = state.allEvents.where((eventItem) {
      final title = eventItem.title.toLowerCase();
      final description = eventItem.description.toLowerCase();
      final location = eventItem.location.name.toLowerCase();
      final region = eventItem.uniqueData['region']?.toString().toLowerCase() ?? '';
      
      return title.contains(query) || 
             description.contains(query) ||
             location.contains(query) ||
             region.contains(query);
    }).toList();
    
    emit(state.copyWith(
      searchQuery: query,
      searchResults: results,
    ));
  }
  
  Future<void> _onLoadEventsForComparison(
    LoadEventsForComparison event,
    Emitter<ComparisonState> emit,
  ) async {
    emit(state.copyWith(status: ComparisonStatus.loading));
    
    try {
      final events = await _eventsRepository.loadEvents();
      
      emit(state.copyWith(
        status: ComparisonStatus.loaded,
        allEvents: events,
        recentlyViewedEvents: _recentlyViewedService.recentEvents,
      ));
      
      // If there's an active search query, re-run the search with loaded events
      if (state.searchQuery.isNotEmpty) {
        add(SearchEventsForComparison(state.searchQuery));
      }
    } catch (error) {
      emit(state.copyWith(
        status: ComparisonStatus.error,
        errorMessage: 'Failed to load events: $error',
      ));
    }
  }
  
  void _onMarkEventAsViewed(
    MarkEventAsViewed event,
    Emitter<ComparisonState> emit,
  ) {
    _recentlyViewedService.addEvent(event.event);
    
    emit(state.copyWith(
      recentlyViewedEvents: _recentlyViewedService.recentEvents,
    ));
  }
}