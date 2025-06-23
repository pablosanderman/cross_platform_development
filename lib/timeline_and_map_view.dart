import 'package:flutter/material.dart';

/// TimelineMapView is now handled directly in app.dart when currentPageIndex == 0
/// This widget serves as a placeholder since the nav items point to it,
/// but the actual split-screen logic is implemented in MyApp's BlocBuilder
class TimelineMapView extends StatelessWidget {
  const TimelineMapView({super.key});

  @override
  Widget build(BuildContext context) {
    // Return an empty container since the timeline/map split-screen
    // is handled directly in app.dart when currentPageIndex == 0
    return const SizedBox.shrink();
  }
}
