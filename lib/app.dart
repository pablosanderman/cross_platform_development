import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'navigation/navigation.dart';

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
                  // If we're on page 0, show the timeline/map split-screen or event details
                  if (navState.currentPageIndex == 0) {
                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          
                          // Always build the standard timeline/map layout
                          // Event details will be shown as overlay if needed
                          
                          // Standard timeline/map layout
                          final bothVisible = navState.showTimeline && navState.showMap;

                          // Calculate widths based on visibility
                          double timelineWidth = 0;
                          double mapWidth = 0;

                          if (bothVisible) {
                            // Both visible: split the space equally
                            timelineWidth = availableWidth / 2;
                            mapWidth = availableWidth / 2;
                          } else if (navState.showTimeline) {
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
                                left: bothVisible
                                    ? timelineWidth
                                    : (navState.showMap ? 0 : availableWidth),
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
                              // Event details overlay
                              if (navState.showEventDetails)
                                _buildEventDetailsOverlay(
                                  navState,
                                  availableWidth,
                                  constraints.maxHeight,
                                ),
                            ],
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
    );
  }

  /// Build the event details overlay
  Widget _buildEventDetailsOverlay(
    NavigationState navState,
    double availableWidth,
    double availableHeight,
  ) {
    // Handle different layout scenarios
    final bothVisible = navState.showTimeline && navState.showMap;
    final timelineOnly = navState.showTimeline && !navState.showMap;
    final mapOnly = !navState.showTimeline && navState.showMap;
    
    double overlayLeft;
    double overlayWidth;
    
    if (bothVisible) {
      // Split screen mode
      final halfWidth = availableWidth / 2;
      if (navState.detailsSource == EventDetailsSource.timeline) {
        // Timeline source: Show event details on right side (over map area)
        overlayLeft = halfWidth;
        overlayWidth = halfWidth;
      } else {
        // Map source: Show event details on left side (over timeline area)
        overlayLeft = 0;
        overlayWidth = halfWidth;
      }
    } else if (timelineOnly) {
      // Full screen timeline
      overlayLeft = availableWidth * 0.4; // Start at 40% from left
      overlayWidth = availableWidth * 0.6; // Take 60% of width
    } else if (mapOnly) {
      // Full screen map
      overlayLeft = 0;
      overlayWidth = availableWidth * 0.6; // Take 60% of width
    } else {
      // Fallback - shouldn't happen
      overlayLeft = availableWidth * 0.3;
      overlayWidth = availableWidth * 0.7;
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
