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
import 'shared/utils/platform_utils.dart';

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
        body: PlatformUtils.isDesktop 
          ? WindowBorder(
              color: borderColor,
              width: 1,
              child: _buildBody(),
            )
          : SafeArea(
              child: _buildBody(),
            ),
      ),
      routes: {'/comparison': (context) => const ComparisonResultsPage()},
    );
  }

  Widget _buildBody() {
    return Column(
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
                                      // Both visible: use platform-appropriate layout
                                      PlatformUtils.isMobile
                                        ? _buildMobileVerticalSplit()
                                        : ResizableSplitView(
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
                                    // Floating Action Buttons - positioned based on platform
                                    if (!navState.showEventDetails)
                                      ..._buildFABs(navState),
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
                    // For other pages, use the nav_item system - wrap in Expanded for consistent layout
                    final currentIndex = navState.currentPageIndex == 1
                        ? navState.currentPageIndex - 1
                        : navState.currentPageIndex;

                    return Expanded(
                      child: BlocBuilder<NavItemsCubit, NavItemsState>(
                        builder: (context, itemsState) {
                          return itemsState.items[currentIndex].page;
                        },
                      ),
                    );
                  }
                },
              ),
            ],
          );
  }

  /// Build vertical split layout for mobile (map top, timeline bottom) with resize handle
  Widget _buildMobileVerticalSplit() {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        return _VerticalResizableSplitView(
          topChild: const MapPage(),
          bottomChild: const TimelinePage(),
          splitRatio: navState.mobileSplitRatio ?? 0.4, // Default 40% for map
          minTopHeight: 200.0,
          minBottomHeight: 250.0,
        );
      },
    );
  }

  /// Build FABs positioned for mobile vs desktop
  List<Widget> _buildFABs(NavigationState navState) {
    if (PlatformUtils.isMobile) {
      return [
        // Timeline/Map pills centered at bottom (mobile design)
        Positioned(
          bottom: 16,
          left: 0,
          right: 104, // Leave space for FABs on the right (2 FABs + padding)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimelineMapPill(
                label: 'Timeline',
                isActive: navState.showTimeline,
                onTap: () => context.read<NavigationBloc>().add(ToggleTimeline()),
              ),
              const SizedBox(width: 12),
              _TimelineMapPill(
                label: 'Map',
                isActive: navState.showMap,
                onTap: () => context.read<NavigationBloc>().add(ToggleMap()),
              ),
            ],
          ),
        ),
        // Eye/Add buttons in absolute bottom right corner
        Positioned(
          right: 16,
          bottom: 16,
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
      ];
    } else {
      // Desktop: Keep original positioning
      return [
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
      ];
    }
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
    // Calculate event details width
    final double eventDetailsWidth;
    
    if (PlatformUtils.isMobile) {
      // On mobile, use full width for event details
      eventDetailsWidth = availableWidth;
    } else {
      // On desktop, use split view with minimum/maximum constraints
      final minDetailsWidth = 400.0;
      final maxDetailsWidth = availableWidth - 350.0; // Leave at least 350px for main content
      
      // Ensure maxDetailsWidth is not less than minDetailsWidth
      final safeMaxWidth = maxDetailsWidth < minDetailsWidth ? availableWidth : maxDetailsWidth;
      
      eventDetailsWidth = (availableWidth * navState.eventDetailsSplitRatio)
          .clamp(minDetailsWidth, safeMaxWidth);
    }

    double overlayLeft;

    if (PlatformUtils.isMobile) {
      // On mobile, always show overlay from left side (full screen)
      overlayLeft = 0;
    } else {
      // On desktop, position based on source
      if (navState.detailsSource == EventDetailsSource.timeline) {
        // Timeline source: Show event details on right side
        overlayLeft = availableWidth - eventDetailsWidth;
      } else {
        // Map source: Show event details on left side
        overlayLeft = 0;
      }
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

/// Vertical resizable split view for mobile (top/bottom layout)
class _VerticalResizableSplitView extends StatefulWidget {
  final Widget topChild;
  final Widget bottomChild;
  final double splitRatio;
  final double minTopHeight;
  final double minBottomHeight;
  static const double dividerHeight = 6.0;

  const _VerticalResizableSplitView({
    required this.topChild,
    required this.bottomChild,
    required this.splitRatio,
    this.minTopHeight = 150.0,
    this.minBottomHeight = 200.0,
  });

  @override
  State<_VerticalResizableSplitView> createState() => _VerticalResizableSplitViewState();
}

class _VerticalResizableSplitViewState extends State<_VerticalResizableSplitView> {
  double? _initialRatio;
  double? _startY;
  double? _availableHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        _availableHeight = availableHeight;

        // Calculate effective heights based on split ratio
        final contentHeight = availableHeight - _VerticalResizableSplitView.dividerHeight;
        final topHeight = contentHeight * widget.splitRatio;
        final bottomHeight = contentHeight * (1.0 - widget.splitRatio);

        return Stack(
          children: [
            // Top child
            Positioned(
              left: 0,
              top: 0,
              width: constraints.maxWidth,
              height: topHeight,
              child: ClipRect(child: widget.topChild),
            ),
            // Bottom child
            Positioned(
              left: 0,
              top: topHeight + _VerticalResizableSplitView.dividerHeight,
              width: constraints.maxWidth,
              height: bottomHeight,
              child: ClipRect(child: widget.bottomChild),
            ),
            // Divider (resize handle)
            Positioned(
              left: 0,
              top: topHeight,
              width: constraints.maxWidth,
              height: _VerticalResizableSplitView.dividerHeight,
              child: _VerticalResizeDivider(
                onDragStarted: () {
                  _initialRatio = widget.splitRatio;
                },
                onDragUpdate: (details) {
                  if (_initialRatio != null && _availableHeight != null) {
                    final deltaY = details.globalPosition.dy - (_startY ?? details.globalPosition.dy);
                    if (_startY == null) {
                      _startY = details.globalPosition.dy;
                      return;
                    }

                    // Calculate new ratio based on drag delta
                    final contentHeight = _availableHeight! - _VerticalResizableSplitView.dividerHeight;
                    final deltaRatio = deltaY / contentHeight;
                    final newRatio = _initialRatio! + deltaRatio;

                    // Apply minimum height constraints
                    final minTopRatio = widget.minTopHeight / contentHeight;
                    final minBottomRatio = widget.minBottomHeight / contentHeight;
                    final maxTopRatio = 1.0 - minBottomRatio;

                    final constrainedRatio = newRatio.clamp(minTopRatio, maxTopRatio);

                    // Update the mobile split ratio via NavigationBloc
                    context.read<NavigationBloc>().add(
                      UpdateMobileSplitRatio(constrainedRatio),
                    );
                  }
                },
                onDragEnded: () {
                  _initialRatio = null;
                  _startY = null;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The visual divider that handles vertical drag gestures for mobile resizing
class _VerticalResizeDivider extends StatefulWidget {
  final VoidCallback onDragStarted;
  final Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onDragEnded;

  const _VerticalResizeDivider({
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  @override
  State<_VerticalResizeDivider> createState() => _VerticalResizeDividerState();
}

class _VerticalResizeDividerState extends State<_VerticalResizeDivider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() => _isDragging = true);
        widget.onDragStarted();
      },
      onPanUpdate: widget.onDragUpdate,
      onPanEnd: (details) {
        setState(() => _isDragging = false);
        widget.onDragEnded();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _isDragging
              ? Colors.blue.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(
              color: _isDragging
                  ? Colors.blue.withValues(alpha: 0.8)
                  : Colors.grey.withValues(alpha: 0.5),
              width: 1,
            ),
            bottom: BorderSide(
              color: _isDragging
                  ? Colors.blue.withValues(alpha: 0.8)
                  : Colors.grey.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: _isDragging
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

/// Timeline/Map pill widget for mobile design
class _TimelineMapPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TimelineMapPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
