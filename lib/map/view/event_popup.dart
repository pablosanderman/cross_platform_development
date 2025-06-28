import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/navigation/navigation.dart';

/// {@template event_popup}
/// A popup widget that displays event details in a bottom-centered floating overlay.
/// Matches the Figma design with navigation for multiple events.
/// {@endtemplate}
class EventPopup extends StatelessWidget {
  /// {@macro event_popup}
  const EventPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        if (!state.showPopup || state.popupEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentEvent = state.popupEvents[state.popupCurrentIndex];
        final hasMultipleEvents = state.popupEvents.length > 1;

        // Responsive sizing based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isVeryNarrow = screenWidth < 400;

        return Stack(
          children: [
            // Bottom-centered popup with navigation controls above
            Positioned(
              left: 16,
              right: 16,
              bottom: 20, // Less space from bottom on mobile
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile
                        ? screenWidth *
                              0.9 // 90% of screen width on mobile
                        : 600, // Fixed max width for desktop
                    minWidth: isVeryNarrow
                        ? screenWidth *
                              0.85 // Very narrow screens
                        : isMobile
                        ? 280 // Smaller minimum for mobile
                        : 400, // Desktop minimum
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top controls row (navigation + close button)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Navigation controls (left side) - only for multiple events
                          if (hasMultipleEvents)
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 12,
                                  vertical: isMobile ? 4 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => context
                                          .read<MapCubit>()
                                          .previousPopupEvent(),
                                      icon: const Icon(Icons.chevron_left),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: isMobile ? 16 : 20,
                                    ),
                                    SizedBox(width: isMobile ? 4 : 8),
                                    Text(
                                      '${state.popupCurrentIndex + 1} of ${state.popupEvents.length}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 4 : 8),
                                    IconButton(
                                      onPressed: () => context
                                          .read<MapCubit>()
                                          .nextPopupEvent(),
                                      icon: const Icon(Icons.chevron_right),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: isMobile ? 16 : 20,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(), // Empty space when no navigation needed
                          // Close button (right side)
                          Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    context.read<MapCubit>().closePopup(),
                                icon: const Icon(Icons.close),
                                padding: EdgeInsets.all(isMobile ? 6 : 8),
                                constraints: const BoxConstraints(),
                                iconSize: isMobile ? 16 : 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: isMobile ? 6 : 8,
                      ), // Space between controls and popup
                      // Main popup content
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main content
                              Padding(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                child: isMobile
                                    ? Column(
                                        // Mobile: vertical layout
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Image at top for mobile
                                          Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<MapCubit>()
                                                    .closePopup();
                                                context
                                                    .read<NavigationBloc>()
                                                    .add(
                                                      ShowEventDetails(
                                                        currentEvent,
                                                        EventDetailsSource.map,
                                                      ),
                                                    );
                                              },
                                              child: Container(
                                                width: isVeryNarrow ? 60 : 80,
                                                height: isVeryNarrow ? 40 : 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.image,
                                                  size: isVeryNarrow ? 20 : 24,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Event details below image
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Clickable title
                                              GestureDetector(
                                                onTap: () {
                                                  context
                                                      .read<MapCubit>()
                                                      .closePopup();
                                                  context
                                                      .read<NavigationBloc>()
                                                      .add(
                                                        ShowEventDetails(
                                                          currentEvent,
                                                          EventDetailsSource
                                                              .map,
                                                        ),
                                                      );
                                                },
                                                child: Text(
                                                  currentEvent.title,
                                                  style: TextStyle(
                                                    fontSize: isVeryNarrow
                                                        ? 16
                                                        : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              // Date range
                                              Text(
                                                _formatDateRange(currentEvent),
                                                style: TextStyle(
                                                  fontSize: isVeryNarrow
                                                      ? 12
                                                      : 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              // Description
                                              Text(
                                                currentEvent.displayDescription,
                                                style: TextStyle(
                                                  fontSize: isVeryNarrow
                                                      ? 11
                                                      : 12,
                                                  height: 1.3,
                                                ),
                                                maxLines: isVeryNarrow ? 2 : 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 8),
                                              // View on Timeline button
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    context
                                                        .read<MapCubit>()
                                                        .navigateToTimeline(
                                                          currentEvent,
                                                        );
                                                  },
                                                  icon: Icon(
                                                    Icons.timeline,
                                                    size: isVeryNarrow
                                                        ? 12
                                                        : 14,
                                                  ),
                                                  label: Text(
                                                    'View on Timeline',
                                                    style: TextStyle(
                                                      fontSize: isVeryNarrow
                                                          ? 11
                                                          : 12,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  isVeryNarrow
                                                                  ? 8
                                                                  : 12,
                                                              vertical:
                                                                  isVeryNarrow
                                                                  ? 4
                                                                  : 6,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Row(
                                        // Desktop: horizontal layout
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Clickable image placeholder
                                          GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<MapCubit>()
                                                  .closePopup();
                                              context
                                                  .read<NavigationBloc>()
                                                  .add(
                                                    ShowEventDetails(
                                                      currentEvent,
                                                      EventDetailsSource.map,
                                                    ),
                                                  );
                                            },
                                            child: Container(
                                              width: 120,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Event details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Clickable title
                                                GestureDetector(
                                                  onTap: () {
                                                    context
                                                        .read<MapCubit>()
                                                        .closePopup();
                                                    context
                                                        .read<NavigationBloc>()
                                                        .add(
                                                          ShowEventDetails(
                                                            currentEvent,
                                                            EventDetailsSource
                                                                .map,
                                                          ),
                                                        );
                                                  },
                                                  child: Text(
                                                    currentEvent.title,
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Date range
                                                Text(
                                                  _formatDateRange(
                                                    currentEvent,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                // Description
                                                Text(
                                                  currentEvent
                                                      .displayDescription,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                // Tags
                                                Text(
                                                  _formatTags(currentEvent),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                // View on Timeline button
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {
                                                      context
                                                          .read<MapCubit>()
                                                          .navigateToTimeline(
                                                            currentEvent,
                                                          );
                                                    },
                                                    icon: const Icon(
                                                      Icons.timeline,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'View on Timeline',
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Format date range for display
  String _formatDateRange(Event event) {
    final formatter = DateFormat('d MMMM yyyy');

    switch (event.type) {
      case EventType.point:
        return formatter.format(event.effectiveStartTime);
      case EventType.period:
        final start = formatter.format(event.effectiveStartTime);
        final endTime = event.effectiveEndTime;
        if (endTime != null) {
          final end = formatter.format(endTime);
          return '$start - $end';
        } else {
          return start; // Fallback to just start date if no end time
        }
      case EventType.grouped:
        final start = formatter.format(event.effectiveStartTime);
        final endTime = event.effectiveEndTime;
        if (endTime != null) {
          final end = formatter.format(endTime);
          return '$start - $end';
        } else {
          return start; // Fallback to just start date if no end time
        }
    }
  }

  /// Format tags for display
  String _formatTags(Event event) {
    final tags = <String>[];

    // Add event type as tag
    tags.add(event.type.name.toUpperCase());

    // Add location if available
    if (event.properties?['location'] != null) {
      tags.add(event.properties!['location']);
    }

    // Add region if available
    if (event.properties?['region'] != null) {
      tags.add(event.properties!['region']);
    }

    return 'Tags: ${tags.join(', ')}';
  }
}
