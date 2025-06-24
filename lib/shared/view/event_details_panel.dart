import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/shared/models/event.dart';
import 'package:cross_platform_development/navigation/navigation.dart';

/// {@template event_details_panel}
/// A bare bones event details panel - empty and ready for implementation
/// {@endtemplate}
class EventDetailsPanel extends StatelessWidget {
  /// {@macro event_details_panel}
  const EventDetailsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        final event = navState.selectedEventForDetails;
        final source = navState.detailsSource;

        if (event == null || source == null) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.white,
          child: const Center(
            child: Text('Event Details Panel - Ready for Implementation'),
          ),
        );
      },
    );
  }
}
