import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/map/map.dart';
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
              Expanded(
                child: BlocBuilder<NavigationBloc, NavigationState>(
                  builder: (context, state) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final bothVisible = state.showTimeline && state.showMap;

                        // Calculate widths based on visibility
                        double timelineWidth = 0;
                        double mapWidth = 0;

                        if (bothVisible) {
                          // Both visible: split the space equally
                          timelineWidth = availableWidth / 2;
                          mapWidth = availableWidth / 2;
                        } else if (state.showTimeline) {
                          // Only timeline visible: take full width
                          timelineWidth = availableWidth;
                          mapWidth = 0;
                        } else if (state.showMap) {
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
                              width: state.showTimeline ? timelineWidth : 0,
                              height: constraints.maxHeight,
                              child: ClipRect(
                                child: Visibility(
                                  visible: state.showTimeline,
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
                                  : (state.showMap ? 0 : availableWidth),
                              top: 0,
                              width: state.showMap ? mapWidth : 0,
                              height: constraints.maxHeight,
                              child: ClipRect(
                                child: Visibility(
                                  visible: state.showMap,
                                  maintainState: true,
                                  maintainAnimation: true,
                                  maintainSize: false,
                                  child: const MapPage(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const backgroundStartColor = Color(0xFFFFD500);

class RightSide extends StatelessWidget {
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: backgroundStartColor,
        child: Column(children: [Text("MAPMAPMAP")]),
      ),
    );
  }
}
