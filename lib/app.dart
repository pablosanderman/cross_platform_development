import 'package:flutter/material.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_app}
/// A [MaterialApp] which sets the `home` to [TimelinePage].
/// {@endtemplate}
class TimelineApp extends MaterialApp {
  /// {@macro timeline_app}
  const TimelineApp({super.key})
    : super(home: const TimelinePage(), debugShowCheckedModeBanner: false);
}
