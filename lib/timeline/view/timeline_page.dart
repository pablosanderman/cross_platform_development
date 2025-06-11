import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_page}
/// A [StatelessWidget] which is responsible for providing a
/// [TimelineCubit] instance to the [TimelineView].
/// {@endtemplate}
class TimelinePage extends StatelessWidget {
  /// {@macro timeline_page}
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimelineCubit(),
      child: const TimelineView(),
    );
  }
}
