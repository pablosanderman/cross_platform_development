import 'package:equatable/equatable.dart';
import '../models/models.dart';
import '../../shared/models/models.dart';

enum ComparisonStatus { initial, loading, loaded, error }

class ComparisonState extends Equatable {
  final ComparisonStatus status;
  final List<ComparisonEventItem> comparisonList;
  final bool isFloatingListVisible;
  final bool isSelectionOverlayVisible;
  final List<Event> allEvents;
  final List<Event> searchResults;
  final List<Event> recentlyViewedEvents;
  final String searchQuery;
  final String? errorMessage;
  
  const ComparisonState({
    this.status = ComparisonStatus.initial,
    this.comparisonList = const [],
    this.isFloatingListVisible = true,
    this.isSelectionOverlayVisible = false,
    this.allEvents = const [],
    this.searchResults = const [],
    this.recentlyViewedEvents = const [],
    this.searchQuery = '',
    this.errorMessage,
  });
  
  /// Maximum number of events that can be compared
  static const int maxComparisonItems = 10;
  
  /// Check if the comparison list is at maximum capacity
  bool get isAtMaxCapacity => comparisonList.length >= maxComparisonItems;
  
  /// Check if the comparison list is empty
  bool get isEmpty => comparisonList.isEmpty;
  
  /// Check if an event is already in the comparison list
  bool isEventInComparison(String eventId) {
    return comparisonList.any((item) => item.event.id == eventId);
  }
  
  /// Get the count of items in comparison list
  int get comparisonCount => comparisonList.length;
  
  /// Check if comparison can be performed (need at least 2 events)
  bool get canCompare => comparisonList.length >= 2;
  
  ComparisonState copyWith({
    ComparisonStatus? status,
    List<ComparisonEventItem>? comparisonList,
    bool? isFloatingListVisible,
    bool? isSelectionOverlayVisible,
    List<Event>? allEvents,
    List<Event>? searchResults,
    List<Event>? recentlyViewedEvents,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ComparisonState(
      status: status ?? this.status,
      comparisonList: comparisonList ?? this.comparisonList,
      isFloatingListVisible: isFloatingListVisible ?? this.isFloatingListVisible,
      isSelectionOverlayVisible: isSelectionOverlayVisible ?? this.isSelectionOverlayVisible,
      allEvents: allEvents ?? this.allEvents,
      searchResults: searchResults ?? this.searchResults,
      recentlyViewedEvents: recentlyViewedEvents ?? this.recentlyViewedEvents,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    comparisonList,
    isFloatingListVisible,
    isSelectionOverlayVisible,
    allEvents,
    searchResults,
    recentlyViewedEvents,
    searchQuery,
    errorMessage,
  ];
}