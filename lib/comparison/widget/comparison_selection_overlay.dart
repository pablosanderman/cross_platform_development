import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/comparison_bloc.dart';
import '../bloc/comparison_event.dart';
import '../bloc/comparison_state.dart';
import '../../shared/models/models.dart';

class ComparisonSelectionOverlay extends StatefulWidget {
  const ComparisonSelectionOverlay({super.key});

  @override
  State<ComparisonSelectionOverlay> createState() => _ComparisonSelectionOverlayState();
}

class _ComparisonSelectionOverlayState extends State<ComparisonSelectionOverlay> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComparisonBloc, ComparisonState>(
      builder: (context, state) {
        if (!state.isSelectionOverlayVisible) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              constraints: const BoxConstraints(
                maxWidth: 800,
                maxHeight: 700,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add Events to Compare',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            context.read<ComparisonBloc>().add(
                                  const HideComparisonSelectionOverlay(),
                                );
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current comparison list
                          if (state.comparisonList.isNotEmpty) ...[
                            Text(
                              'Current Comparison List (${state.comparisonCount}/${ComparisonState.maxComparisonItems})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.comparisonList.map((item) {
                                  return Chip(
                                    label: Text(
                                      item.event.title,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      context.read<ComparisonBloc>().add(
                                            RemoveEventFromComparison(item.event.id),
                                          );
                                    },
                                    backgroundColor: Colors.white,
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Search section
                          Text(
                            'Search Events',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Type here to search events...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (query) {
                              context.read<ComparisonBloc>().add(
                                    SearchEventsForComparison(query),
                                  );
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Results
                          Expanded(
                            child: _buildSearchResults(context, state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, ComparisonState state) {
    if (state.status == ComparisonStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show search results if there's a query
    if (state.searchQuery.isNotEmpty) {
      if (state.searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${state.searchResults.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.searchResults.length,
              itemBuilder: (context, index) {
                final event = state.searchResults[index];
                return _EventCard(
                  event: event,
                  isInComparison: state.isEventInComparison(event.id),
                  isAtMaxCapacity: state.isAtMaxCapacity,
                  onAdd: () {
                    context.read<ComparisonBloc>().add(AddEventToComparison(event));
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    // Show recently viewed events if no search query
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Viewed Events:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 12),
        if (state.recentlyViewedEvents.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recently viewed events',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'View some events first to see them here',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.recentlyViewedEvents.length,
              itemBuilder: (context, index) {
                final event = state.recentlyViewedEvents[index];
                return _EventGridCard(
                  event: event,
                  isInComparison: state.isEventInComparison(event.id),
                  isAtMaxCapacity: state.isAtMaxCapacity,
                  onAdd: () {
                    context.read<ComparisonBloc>().add(AddEventToComparison(event));
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isInComparison;
  final bool isAtMaxCapacity;
  final VoidCallback onAdd;

  const _EventCard({
    required this.event,
    required this.isInComparison,
    required this.isAtMaxCapacity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Event type indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getEventTypeColor(event.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getEventLocation(event),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(event.effectiveStartTime),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Add button
            IconButton(
              onPressed: isInComparison || isAtMaxCapacity ? null : onAdd,
              icon: Icon(
                isInComparison ? Icons.check : Icons.add,
                color: isInComparison 
                    ? Colors.green 
                    : (isAtMaxCapacity ? Colors.grey : Colors.blue),
              ),
              tooltip: isInComparison 
                  ? 'Already in comparison' 
                  : (isAtMaxCapacity ? 'Maximum items reached' : 'Add to comparison'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.point:
        return Colors.orange;
      case EventType.period:
        return Colors.green;
      case EventType.grouped:
        return Colors.purple;
    }
  }

  String _getEventLocation(Event event) {
    final location = event.properties?['location']?.toString();
    final region = event.properties?['region']?.toString();
    
    if (location != null && region != null) {
      return '$location, $region';
    } else if (location != null) {
      return location;
    } else if (region != null) {
      return region;
    } else {
      return 'Unknown location';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _EventGridCard extends StatelessWidget {
  final Event event;
  final bool isInComparison;
  final bool isAtMaxCapacity;
  final VoidCallback onAdd;

  const _EventGridCard({
    required this.event,
    required this.isInComparison,
    required this.isAtMaxCapacity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isInComparison || isAtMaxCapacity ? null : onAdd,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isInComparison ? Icons.check_circle : Icons.add_circle_outline,
                    size: 20,
                    color: isInComparison 
                        ? Colors.green 
                        : (isAtMaxCapacity ? Colors.grey : Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _getEventLocation(event),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.point:
        return Colors.orange;
      case EventType.period:
        return Colors.green;
      case EventType.grouped:
        return Colors.purple;
    }
  }

  String _getEventLocation(Event event) {
    final location = event.properties?['location']?.toString();
    final region = event.properties?['region']?.toString();
    
    if (location != null && region != null) {
      return '$location, $region';
    } else if (location != null) {
      return location;
    } else if (region != null) {
      return region;
    } else {
      return 'Unknown location';
    }
  }
}