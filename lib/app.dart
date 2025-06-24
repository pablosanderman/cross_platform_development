import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';
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
                  // If we're on page 0, show the timeline/map split-screen with comparison overlay
                  if (navState.currentPageIndex == 0) {
                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final bothVisible =
                              navState.showTimeline && navState.showMap;

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

                          return ComparisonPage(
                            child: Stack(
                              children: [
                                // Timeline - always present but positioned/sized
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  width: navState.showTimeline
                                      ? timelineWidth
                                      : 0,
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
                              ],
                            ),
                          return BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
                            builder: (context, visibilityState) {
                              return Stack(
                                children: [
                                  // Timeline - always present but positioned/sized
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    width: navState.showTimeline
                                        ? timelineWidth
                                        : 0,
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
      routes: {
        '/comparison': (context) => const ComparisonResultsPage(),
      },
    );
  }
}
