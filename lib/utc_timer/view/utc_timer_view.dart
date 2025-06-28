import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cross_platform_development/utc_timer/cubit/utc_timer_cubit.dart';
import 'package:cross_platform_development/shared/utils/platform_utils.dart';

class UtcTimerView extends StatelessWidget {
  const UtcTimerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to listen for DateTime updates from UtcTimeCubit.
    return BlocBuilder<UtcTimeCubit, DateTime>(
      builder: (context, currentTimeUtc) {
        // Format the time only (without UTC label)
        final String formattedTime = DateFormat('HH:mm:ss').format(currentTimeUtc);

        return Container(
          // Add some padding around the time to give it breathing room.
          padding: EdgeInsets.symmetric(
            horizontal: PlatformUtils.isMobile ? 6.0 : 10.0, 
            vertical: 4.0,
          ),
          child: SizedBox(
            width: PlatformUtils.isMobile ? 70.0 : 120.0, // Increased mobile width to fix overflow
            child: PlatformUtils.isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time on top
                    Text(
                      formattedTime,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // UTC label below
                    Text(
                      'UTC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade300,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time and UTC on same line for desktop
                    Text(
                      '$formattedTime UTC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }
}
