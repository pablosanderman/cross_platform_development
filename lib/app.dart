import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:cross_platform_development/resizable_split_view.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'navigation/navigation.dart';
import 'comparison/comparison.dart';
import 'widgets/add_event/add_event_fab.dart';
import 'widgets/add_event/add_event_overlay.dart';

const borderColor = Color(0xFF805306);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showAddEventOverlay = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 1,
          child: Column(
            children: [
              const NavigationView(),
              BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, navState) {
                  // If we're on page 0, show the timeline/map split-screen with all overlays
                  if (navState.currentPageIndex == 0) {
                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;

                          // Always build the standard timeline/map layout
                          // Event details will be shown as overlay if needed
                          // Now with resizable split view support

                          final bothVisible =
                              navState.showTimeline && navState.showMap;

                          // Wrap everything with EventVisibility and Comparison features
                          return BlocBuilder<
                            EventVisibilityCubit,
                            EventVisibilityState
                          >(
                            builder: (context, visibilityState) {
                              return ComparisonPage(
                                child: Stack(
                                  children: [
                                    // Main layout - either resizable split view or single view
                                    if (bothVisible)
                                      // Both visible: use resizable split view
                                      ResizableSplitView(
                                        leftChild: const TimelinePage(),
                                        rightChild: const MapPage(),
                                        splitRatio: navState.splitRatio,
                                        minLeftWidth: 350.0,
                                        minRightWidth: 350.0,
                                      )
                                    else
                                      // Only one component visible: use simple layout
                                      _buildSingleViewLayout(
                                        navState,
                                        constraints,
                                        availableWidth,
                                      ),
                                    // Event details overlay
                                    if (navState.showEventDetails)
                                      _buildEventDetailsOverlay(
                                        navState,
                                        availableWidth,
                                        constraints.maxHeight,
                                      ),
                                    // Floating Action Buttons - hidden when event details are open
                                    if (!navState.showEventDetails)
                                      Positioned(
                                        bottom: 16,
                                        right: 16,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const EventVisibilityFab(),
                                            const SizedBox(height: 8),
                                            AddEventFab(
                                              onPressed: () {
                                                setState(() {
                                                  _showAddEventOverlay = true;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Add Event Overlay
                                    if (_showAddEventOverlay)
                                      AddEventOverlay(
                                        onSubmitted: (eventData) {
                                          setState(() {
                                            _showAddEventOverlay = false;
                                          });
                                          if (eventData != null) {
                                            context
                                                .read<TimelineCubit>()
                                                .addEvent(
                                                  eventData['title'],
                                                  eventData['description'],
                                                  eventData['startTime'],
                                                  eventData['endTime'],
                                                  eventData['latitude'],
                                                  eventData['longitude'],
                                                );
                                          }
                                        },
                                        onCancel: () {
                                          setState(() {
                                            _showAddEventOverlay = false;
                                          });
                                        },
                                      ),
                                    // Event Visibility Panel Overlay
                                    if (visibilityState.panelOpen)
                                      const Positioned.fill(
                                        child: EventVisibilityPanel(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    // For other pages, use the nav_item system - no Expanded wrapper
                    final currentIndex = navState.currentPageIndex == 1
                        ? navState.currentPageIndex - 1
                        : navState.currentPageIndex;

                    return BlocBuilder<NavItemsCubit, NavItemsState>(
                      builder: (context, itemsState) {
                        return itemsState.items[currentIndex].page;
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      routes: {'/comparison': (context) => const ComparisonResultsPage()},
    );
  }

  /// Build single view layout when only timeline or map is visible
  Widget _buildSingleViewLayout(
    NavigationState navState,
    BoxConstraints constraints,
    double availableWidth,
  ) {
    double timelineWidth = 0;
    double mapWidth = 0;

    if (navState.showTimeline) {
      // Only timeline visible: take full width
      timelineWidth = availableWidth;
      mapWidth = 0;
    } else if (navState.showMap) {
      // Only map visible: take full width
      timelineWidth = 0;
      mapWidth = availableWidth;
    }

    return Stack(
      children: [
        // Timeline - always present but positioned/sized
        Positioned(
          left: 0,
          top: 0,
          width: navState.showTimeline ? timelineWidth : 0,
          height: constraints.maxHeight,
          child: ClipRect(
            child: Visibility(
              visible: navState.showTimeline,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: false,
              child: const TimelinePage(),
            ),
          ),
        ),
        // Map - always present but positioned/sized
        Positioned(
          left: navState.showMap ? 0 : availableWidth,
          top: 0,
          width: navState.showMap ? mapWidth : 0,
          height: constraints.maxHeight,
          child: ClipRect(
            child: Visibility(
              visible: navState.showMap,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: false,
              child: const MapPage(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the event details overlay with resizable functionality
  Widget _buildEventDetailsOverlay(
    NavigationState navState,
    double availableWidth,
    double availableHeight,
  ) {
    // Calculate minimum and maximum widths for event details
    final minDetailsWidth = 400.0;
    final maxDetailsWidth =
        availableWidth - 350.0; // Leave at least 350px for main content

    // Calculate event details width based on split ratio
    final eventDetailsWidth = (availableWidth * navState.eventDetailsSplitRatio)
        .clamp(minDetailsWidth, maxDetailsWidth);

    double overlayLeft;

    if (navState.detailsSource == EventDetailsSource.timeline) {
      // Timeline source: Show event details on right side
      overlayLeft = availableWidth - eventDetailsWidth;
    } else {
      // Map source: Show event details on left side
      overlayLeft = 0;
    }

    return Stack(
      children: [
        // Event details panel only - no duplicate main content area
        Positioned(
          left: overlayLeft,
          top: 0,
          width: eventDetailsWidth,
          height: availableHeight,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: Offset(overlayLeft > 0 ? -2 : 2, 0),
                ),
              ],
            ),
            child: const EventDetailsPanel(),
          ),
        ),
      ],
    );
  }
}

/// Resizable divider widget for event details overlay
class _EventDetailsResizeDivider extends StatefulWidget {
  final double availableWidth;
  final double minDetailsWidth;
  final double maxDetailsWidth;
  final bool isDetailsOnRight;

  const _EventDetailsResizeDivider({
    required this.availableWidth,
    required this.minDetailsWidth,
    required this.maxDetailsWidth,
    required this.isDetailsOnRight,
  });

  @override
  State<_EventDetailsResizeDivider> createState() =>
      _EventDetailsResizeDividerState();
}

class _EventDetailsResizeDividerState
    extends State<_EventDetailsResizeDivider> {
  bool _isHovering = false;
  bool _isDragging = false;
  double? _initialRatio;
  double? _startX;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onPanStart: (details) {
          setState(() => _isDragging = true);
          _initialRatio = context
              .read<NavigationBloc>()
              .state
              .eventDetailsSplitRatio;
          _startX = details.globalPosition.dx;
        },
        onPanUpdate: (details) {
          if (_initialRatio != null && _startX != null) {
            final deltaX = details.globalPosition.dx - _startX!;

            // Calculate new ratio based on drag delta
            final deltaRatio = widget.isDetailsOnRight
                ? -deltaX /
                      widget
                          .availableWidth // Reverse direction for right-side details
                : deltaX / widget.availableWidth;
            final newRatio = _initialRatio! + deltaRatio;

            // Apply minimum and maximum width constraints
            final minRatio = widget.minDetailsWidth / widget.availableWidth;
            final maxRatio = widget.maxDetailsWidth / widget.availableWidth;

            final constrainedRatio = newRatio.clamp(minRatio, maxRatio);

            // Update the event details split ratio via NavigationBloc
            context.read<NavigationBloc>().add(
              UpdateEventDetailsSplitRatio(constrainedRatio),
            );
          }
        },
        onPanEnd: (details) {
          setState(() => _isDragging = false);
          _initialRatio = null;
          _startX = null;
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isDragging
                ? Colors.blue.withValues(alpha: 0.4)
                : _isHovering
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border(
              left: BorderSide(
                color: _isDragging
                    ? Colors.blue.withValues(alpha: 0.8)
                    : _isHovering
                    ? Colors.blue.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
              right: BorderSide(
                color: _isDragging
                    ? Colors.blue.withValues(alpha: 0.8)
                    : _isHovering
                    ? Colors.blue.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
