import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cross_platform_development/utc_timer/cubit/utc_timer_cubit.dart';

class UtcTimerView extends StatelessWidget {
  const UtcTimerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to listen for DateTime updates from UtcTimeCubit.
    return BlocBuilder<UtcTimeCubit, DateTime>(
      builder: (context, currentTimeUtc) {
        // Format the UTC time for a compact display in the navigation bar.
        // We'll show only hours, minutes, and seconds to save space.
        final String formattedTime = DateFormat('HH:mm:ss' ' UTC').format(currentTimeUtc);

        return Container(
          // Add some padding around the time to give it breathing room.
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),

          child: Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }
}
