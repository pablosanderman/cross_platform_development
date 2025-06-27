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

        return Stack(
          children: [
            // Bottom-centered popup with navigation controls above
            Positioned(
              left: 16,
              right: 16,
              bottom: 80, // Space from bottom
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600, // Fixed max width for consistent sizing
                    minWidth: 400, // Minimum width for readability
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
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
                                      iconSize: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${state.popupCurrentIndex + 1} of ${state.popupEvents.length}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => context
                                          .read<MapCubit>()
                                          .nextPopupEvent(),
                                      icon: const Icon(Icons.chevron_right),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 20,
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
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                iconSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
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
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Clickable image placeholder
                                    GestureDetector(
                                      onTap: () {
                                        // Hide popup without clearing selection and show event details
                                        context.read<MapCubit>().closePopup();
                                        context.read<NavigationBloc>().add(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              // Hide popup without clearing selection and show event details
                                              context.read<MapCubit>().closePopup();
                                              context
                                                  .read<NavigationBloc>()
                                                  .add(
                                                    ShowEventDetails(
                                                      currentEvent,
                                                      EventDetailsSource.map,
                                                    ),
                                                  );
                                            },
                                            child: Text(
                                              currentEvent.title,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Date range
                                          Text(
                                            _formatDateRange(currentEvent),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Description
                                          Text(
                                            currentEvent.displayDescription,
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
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
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
        final end = formatter.format(event.effectiveEndTime!);
        return '$start - $end';
      case EventType.grouped:
        final start = formatter.format(event.effectiveStartTime);
        final end = formatter.format(event.effectiveEndTime!);
        return '$start - $end';
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
