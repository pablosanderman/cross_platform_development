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
          child: Center(
            child: Container(
              width: 1000, // Fixed width (approximately 2/3 of 1440px screen)
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
                  
                  // Selected events (growing list)
                  ...state.comparisonList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EventInputField(
                        label: 'Event ${index + 1}',
                        event: item.event,
                        onClear: () {
                          context.read<ComparisonBloc>().add(
                                RemoveEventFromComparison(item.event.id),
                              );
                        },
                      ),
                    );
                  }).toList(),
                  
                  // Search field with Compare button
                  Stack(
                    children: [
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
                              // Close the overlay after navigating
                              context.read<ComparisonBloc>().add(const HideComparisonSelectionOverlay());
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
                      // Search results dropdown (positioned absolutely)
                      if (state.searchQuery.isNotEmpty && state.searchResults.isNotEmpty)
                        Positioned(
                          top: 52, // Just below the search field
                          left: 0,
                          right: 136, // Leave space for the compare button
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.searchResults.take(5).length, // Limit to 5 results
                              itemBuilder: (context, index) {
                                final event = state.searchResults[index];
                                final isInComparison = state.isEventInComparison(event.id);
                                final isAtMaxCapacity = state.isAtMaxCapacity;
                                
                                return _SearchResultItem(
                                  event: event,
                                  isInComparison: isInComparison,
                                  isAtMaxCapacity: isAtMaxCapacity,
                                  isLast: index == state.searchResults.take(5).length - 1,
                                  onTap: isInComparison || isAtMaxCapacity ? null : () {
                                    context.read<ComparisonBloc>().add(AddEventToComparison(event));
                                    _searchController.clear();
                                    context.read<ComparisonBloc>().add(const SearchEventsForComparison(''));
                                  },
                                );
                              },
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

    // Show recently viewed events (limit to 6 items in 3x2 grid)
    // When searching, don't show search results in the grid anymore - they're in the dropdown
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
        childAspectRatio: 1.8, // Increased from 1.5 to give more width
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

// Search result item widget with hover effects
class _SearchResultItem extends StatefulWidget {
  final Event event;
  final bool isInComparison;
  final bool isAtMaxCapacity;
  final bool isLast;
  final VoidCallback? onTap;

  const _SearchResultItem({
    required this.event,
    required this.isInComparison,
    required this.isAtMaxCapacity,
    required this.isLast,
    this.onTap,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = !widget.isInComparison && !widget.isAtMaxCapacity;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered && isClickable 
                ? Colors.grey.shade800 
                : Colors.transparent,
            border: Border(
              bottom: widget.isLast
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade700),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: widget.isInComparison || widget.isAtMaxCapacity 
                            ? Colors.grey.shade500
                            : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                                         Text(
                       _getEventLocationStatic(widget.event),
                       style: TextStyle(
                         color: Colors.grey.shade400,
                         fontSize: 12,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                  ],
                ),
              ),
              if (widget.isInComparison)
                const Icon(Icons.check, color: Colors.green, size: 20)
              else if (widget.isAtMaxCapacity)
                Icon(Icons.block, color: Colors.grey.shade500, size: 20)
              else
                const Icon(Icons.add, color: Color(0xFF69A8F8), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static String _getEventLocationStatic(Event event) {
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
        padding: const EdgeInsets.all(8), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: don't take more space than needed
          children: [
            // Event title at top
            Flexible(
              child: Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // Reduced font size
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8), // Fixed spacing instead of Spacer
            // Placeholder image in center
            Center(
              child: Container(
                width: 50, // Reduced size
                height: 30, // Reduced size
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.image,
                  color: Colors.grey.shade400,
                  size: 20, // Reduced icon size
                ),
              ),
            ),
            const SizedBox(height: 8), // Fixed spacing instead of Spacer
            // + button at bottom right
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