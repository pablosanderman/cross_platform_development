import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_page}
/// A [StatelessWidget] which is responsible for providing a
/// [TimelineView] that uses the app-level TimelineCubit.
/// {@endtemplate}
class TimelinePage extends StatelessWidget {
  /// {@macro timeline_page}
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TimelineView();
  }
}
