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
          color: Colors.black.withOpacity(0.8),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button (top-right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<ComparisonBloc>().add(
                                const HideComparisonSelectionOverlay(),
                              );
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Event comparison inputs (stacked vertically)
                  _EventInputField(
                    label: 'Event 1',
                    event: state.comparisonList.isNotEmpty ? state.comparisonList[0].event : null,
                    onClear: state.comparisonList.isNotEmpty ? () {
                      context.read<ComparisonBloc>().add(
                            RemoveEventFromComparison(state.comparisonList[0].event.id),
                          );
                    } : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _EventInputField(
                    label: 'Event 2',
                    event: state.comparisonList.length > 1 ? state.comparisonList[1].event : null,
                    onClear: state.comparisonList.length > 1 ? () {
                      context.read<ComparisonBloc>().add(
                            RemoveEventFromComparison(state.comparisonList[1].event.id),
                          );
                    } : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Search field with Compare button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type here to compare',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (query) {
                              context.read<ComparisonBloc>().add(
                                    SearchEventsForComparison(query),
                                  );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: state.comparisonList.length >= 2 ? () {
                          Navigator.of(context).pushNamed('/comparison');
                        } : null,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: state.comparisonList.length >= 2 
                                ? const Color(0xFF69A8F8) 
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'COMPARE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Recently viewed events section
                  const Text(
                    'Recently Viewed Events:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid of 6 cards (3x2)
                  Expanded(
                    child: _buildRecentlyViewedGrid(context, state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyViewedGrid(BuildContext context, ComparisonState state) {
    if (state.status == ComparisonStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Show search results if there's a search query
    if (state.searchQuery.isNotEmpty) {
      if (state.searchResults.isEmpty) {
        return const Center(
          child: Text(
            'No events found',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.searchResults.take(6).length, // Limit to 6 items
        itemBuilder: (context, index) {
          final event = state.searchResults[index];
          return _RecentlyViewedCard(
            event: event,
            isInComparison: state.isEventInComparison(event.id),
            isAtMaxCapacity: state.isAtMaxCapacity,
            onAdd: () {
              context.read<ComparisonBloc>().add(AddEventToComparison(event));
            },
          );
        },
      );
    }

    // Show recently viewed events (limit to 6 items in 3x2 grid)
    if (state.recentlyViewedEvents.isEmpty) {
      return const Center(
        child: Text(
          'No recently viewed events',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.recentlyViewedEvents.take(6).length, // 3x2 grid = 6 items
      itemBuilder: (context, index) {
        final event = state.recentlyViewedEvents[index];
        return _RecentlyViewedCard(
          event: event,
          isInComparison: state.isEventInComparison(event.id),
          isAtMaxCapacity: state.isAtMaxCapacity,
          onAdd: () {
            context.read<ComparisonBloc>().add(AddEventToComparison(event));
          },
        );
      },
    );
  }
}

// Event input field widget for Event 1 and Event 2
class _EventInputField extends StatelessWidget {
  final String label;
  final Event? event;
  final VoidCallback? onClear;

  const _EventInputField({
    required this.label,
    this.event,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event?.title ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Recently viewed card widget
class _RecentlyViewedCard extends StatelessWidget {
  final Event event;
  final bool isInComparison;
  final bool isAtMaxCapacity;
  final VoidCallback onAdd;

  const _RecentlyViewedCard({
    required this.event,
    required this.isInComparison,
    required this.isAtMaxCapacity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently viewed event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: isInComparison || isAtMaxCapacity ? null : onAdd,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isInComparison 
                          ? Colors.green 
                          : (isAtMaxCapacity ? Colors.grey : const Color(0xFF69A8F8)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isInComparison ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}