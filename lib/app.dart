import 'package:flutter/material.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_app}
/// A [MaterialApp] which sets the `home` to [TimelinePage].
/// {@endtemplate}
class TimelineApp extends MaterialApp {
  /// {@macro timeline_app}
  TimelineApp({super.key})
    : super(
        home: TimelineThemeData(
          theme: const TimelineTheme(),
          child: TimelinePage(provider: TimelineCubit()),
        ),
        debugShowCheckedModeBanner: false,
      );
}
