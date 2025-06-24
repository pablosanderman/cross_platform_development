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

const borderColor = Color(0xFF805306);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
                          
                          final bothVisible = navState.showTimeline && navState.showMap;

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
                                        minLeftWidth: 200.0,
                                        minRightWidth: 200.0,
                                        onSplitRatioChanged: (ratio) {
                                          context.read<NavigationBloc>().add(
                                            UpdateSplitRatio(ratio),
                                          );
                                        },
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
                                    // Event Visibility FAB
                                    const Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: EventVisibilityFab(),
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

  /// Build the event details overlay
  Widget _buildEventDetailsOverlay(
    NavigationState navState,
    double availableWidth,
    double availableHeight,
  ) {
    // Event details always force split-screen mode
    final halfWidth = availableWidth / 2;
    
    double overlayLeft;
    double overlayWidth;
    
    if (navState.detailsSource == EventDetailsSource.timeline) {
      // Timeline source: Show event details on right side (over map area)
      overlayLeft = halfWidth;
      overlayWidth = halfWidth;
    } else {
      // Map source: Show event details on left side (over timeline area)
      overlayLeft = 0;
      overlayWidth = halfWidth;
    }
    
    return Positioned(
      left: overlayLeft,
      top: 0,
      width: overlayWidth,
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
    );
  }
}
