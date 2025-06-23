import 'package:equatable/equatable.dart';
import '../../shared/models/models.dart';

abstract class ComparisonEvent extends Equatable {
  const ComparisonEvent();
  
  @override
  List<Object?> get props => [];
}

/// Add an event to the comparison list
class AddEventToComparison extends ComparisonEvent {
  final Event event;
  
  const AddEventToComparison(this.event);
  
  @override
  List<Object?> get props => [event];
}

/// Remove an event from the comparison list
class RemoveEventFromComparison extends ComparisonEvent {
  final String eventId;
  
  const RemoveEventFromComparison(this.eventId);
  
  @override
  List<Object?> get props => [eventId];
}

/// Clear all events from the comparison list
class ClearComparisonList extends ComparisonEvent {
  const ClearComparisonList();
}

/// Toggle the floating comparison list visibility
class ToggleComparisonListVisibility extends ComparisonEvent {
  const ToggleComparisonListVisibility();
}

/// Show the comparison selection overlay
class ShowComparisonSelectionOverlay extends ComparisonEvent {
  const ShowComparisonSelectionOverlay();
}

/// Hide the comparison selection overlay
class HideComparisonSelectionOverlay extends ComparisonEvent {
  const HideComparisonSelectionOverlay();
}

/// Navigate to comparison results page
class NavigateToComparisonResults extends ComparisonEvent {
  const NavigateToComparisonResults();
}

/// Search events for comparison
class SearchEventsForComparison extends ComparisonEvent {
  final String query;
  
  const SearchEventsForComparison(this.query);
  
  @override
  List<Object?> get props => [query];
}

/// Load all events for comparison selection
class LoadEventsForComparison extends ComparisonEvent {
  const LoadEventsForComparison();
}

/// Mark an event as recently viewed
class MarkEventAsViewed extends ComparisonEvent {
  final Event event;
  
  const MarkEventAsViewed(this.event);
  
  @override
  List<Object?> get props => [event];
}