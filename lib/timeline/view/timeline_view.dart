import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/timeline/models/models.dart';

/// {@template timeline_view}
/// A [StatelessWidget] which reacts to the provided
/// [TimelineCubit] state and notifies it in response to user input.
/// {@endtemplate}
class TimelineView extends StatelessWidget {
  /// {@macro timeline_view}
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<TimelineCubit>().loadTimeline();
    return Scaffold(
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              return Column(
                children: [
                  // Month ruler header
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(children: _buildDynamicHeaders(state)),
                  ),
                  // Timeline grid
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: _buildTimelineRows(state, availableWidth),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildDynamicHeaders(TimelineState state) {
    final duration = state.visibleDuration;
    final start = state.visibleStart;
    final end = state.visibleEnd;

    // Determine ruler type based on duration
    if (duration.inDays < 2) {
      return _buildHourRuler(start, end, duration);
    } else if (duration.inDays < 14) {
      return _buildDayRuler(start, end, duration);
    } else if (duration.inDays < 90) {
      return _buildWeekRuler(start, end, duration);
    } else if (duration.inDays < 730) {
      return _buildMonthRuler(start, end, duration);
    } else if (duration.inDays < 2920) {
      return _buildQuarterRuler(start, end, duration);
    } else {
      return _buildYearRuler(start, end, duration);
    }
  }

  List<Widget> _buildHourRuler(
    DateTime start,
    DateTime end,
    Duration duration,
  ) {
    final hours = duration.inHours;

    // Always use 1-hour segments
    const hourStep = 1;
    final divisions = hours.clamp(
      2,
      24,
    ); // Show all hours, max 24 for readability

    return List.generate(divisions, (index) {
      final segmentStart = start.add(Duration(hours: hourStep * index));
      final hourLabel = '${segmentStart.hour.toString().padLeft(2, '0')}:00';

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              hourLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildDayRuler(DateTime start, DateTime end, Duration duration) {
    final days = duration.inDays;
    final divisions = (days / 1).clamp(2, 7); // 1-day segments, max 7 divisions

    return List.generate(divisions.toInt(), (index) {
      final segmentStart = start.add(
        Duration(days: (days * index / divisions).round()),
      );
      final dayLabel = '${segmentStart.day}/${segmentStart.month}';

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              dayLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildWeekRuler(
    DateTime start,
    DateTime end,
    Duration duration,
  ) {
    final weeks = (duration.inDays / 7).ceil();
    final divisions = (weeks / 1).clamp(
      2,
      6,
    ); // 1-week segments, max 6 divisions

    return List.generate(divisions.toInt(), (index) {
      final segmentStart = start.add(
        Duration(days: (duration.inDays * index / divisions).round()),
      );
      final weekLabel = 'W${_getWeekOfYear(segmentStart)}';

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              weekLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildMonthRuler(
    DateTime start,
    DateTime end,
    Duration duration,
  ) {
    final months = ((end.year - start.year) * 12 + end.month - start.month)
        .clamp(2, 12);
    final divisions = (months / 1).clamp(
      2,
      6,
    ); // 1-month segments, max 6 divisions

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return List.generate(divisions.toInt(), (index) {
      final monthsOffset = (months * index / divisions).round();
      final segmentDate = DateTime(start.year, start.month + monthsOffset);
      final monthLabel = monthNames[segmentDate.month - 1];

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              monthLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildQuarterRuler(
    DateTime start,
    DateTime end,
    Duration duration,
  ) {
    final years = (end.year - start.year + 1);
    final divisions = (years / 1).clamp(
      2,
      4,
    ); // 1-year segments, max 4 divisions

    return List.generate(divisions.toInt(), (index) {
      final yearOffset = (years * index / divisions).round();
      final segmentYear = start.year + yearOffset;
      final yearLabel = segmentYear.toString();

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              yearLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildYearRuler(
    DateTime start,
    DateTime end,
    Duration duration,
  ) {
    final years = (end.year - start.year + 1);
    final yearStep = (years / 5).ceil(); // Group years for readability
    final divisions = (years / yearStep).ceil().clamp(2, 6);

    return List.generate(divisions, (index) {
      final yearOffset = yearStep * index;
      final segmentYear = start.year + yearOffset;
      final yearLabel = segmentYear.toString();

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: index < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              yearLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    });
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  List<Widget> _buildTimelineRows(TimelineState state, double availableWidth) {
    final headerDivisions = _getHeaderDivisions(state);

    return state.rows.map((row) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Stack(
          children: [
            // Vertical grid lines behind events - matching header divisions
            Row(
              children: List.generate(headerDivisions, (columnIndex) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: columnIndex < headerDivisions - 1
                            ? BorderSide(color: Colors.grey[300]!)
                            : BorderSide.none,
                      ),
                    ),
                  ),
                );
              }),
            ),
            // Events on top of grid lines
            ...row.events.map((event) {
              return _buildEventWidget(event, state, availableWidth);
            }),
          ],
        ),
      );
    }).toList();
  }

  int _getHeaderDivisions(TimelineState state) {
    final duration = state.visibleDuration;

    // Return the same number of divisions as the header
    if (duration.inDays < 2) {
      final hours = duration.inHours;
      // Always use 1-hour segments to match _buildHourRuler
      return hours.clamp(2, 24);
    } else if (duration.inDays < 14) {
      final days = duration.inDays;
      return (days / 1).clamp(2, 7).toInt();
    } else if (duration.inDays < 90) {
      final weeks = (duration.inDays / 7).ceil();
      return (weeks / 1).clamp(2, 6).toInt();
    } else if (duration.inDays < 730) {
      final start = state.visibleStart;
      final end = state.visibleEnd;
      final months = ((end.year - start.year) * 12 + end.month - start.month)
          .clamp(2, 12);
      return (months / 1).clamp(2, 6).toInt();
    } else if (duration.inDays < 2920) {
      final start = state.visibleStart;
      final end = state.visibleEnd;
      final years = (end.year - start.year + 1);
      return (years / 1).clamp(2, 4).toInt();
    } else {
      final start = state.visibleStart;
      final end = state.visibleEnd;
      final years = (end.year - start.year + 1);
      final yearStep = (years / 5).ceil();
      return (years / yearStep).ceil().clamp(2, 6);
    }
  }

  Widget _buildEventWidget(
    Event event,
    TimelineState state,
    double availableWidth,
  ) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.red.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
    ];

    final color = colors[event.hashCode % colors.length];
    final isPoint = event.endTime == null;

    // Calculate position based on actual time
    final leftOffset = _getEventPosition(
      event.startTime,
      state,
      availableWidth,
    );
    final width = _getEventWidth(event, state, availableWidth);
    final textWidth = _getEventTextWidth(event, state, availableWidth);

    // Calculate vertical center position dynamically
    const rowHeight = 80.0;
    const eventHeight = 50.0;
    const opacity = 0.97;
    const fontSize = 14.0;
    final verticalCenter =
        (rowHeight - eventHeight) / 2; // This gives us 25px for 80px row

    if (isPoint) {
      // Draw as circle for point events with text extending into the allocated space
      return Positioned(
        left: leftOffset,
        top: verticalCenter,
        child: SizedBox(
          width: textWidth,
          height: eventHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: eventHeight,
                height: eventHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(fontSize: fontSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Draw as rectangular bar for period events with text overflow capability
      return Positioned(
        left: leftOffset,
        top: verticalCenter,
        child: SizedBox(
          width: textWidth, // Use text width for the container
          height: eventHeight,
          child: Stack(
            children: [
              // The actual event rectangle (shows real duration)
              Container(
                width: width,
                height: eventHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Text that can overflow beyond the rectangle
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: fontSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  double _getEventPosition(
    DateTime eventTime,
    TimelineState state,
    double availableWidth,
  ) {
    // Calculate position based on time relative to visible timeline
    final totalDuration = state.visibleEnd.difference(state.visibleStart);
    final eventOffset = eventTime.difference(state.visibleStart);

    // Calculate position as a ratio of the timeline, then scale to available width
    final positionRatio =
        eventOffset.inMilliseconds / totalDuration.inMilliseconds;

    // Assume a fixed timeline width of 800 pixels for consistent positioning
    return positionRatio * availableWidth;
  }

  double _getEventWidth(
    Event event,
    TimelineState state,
    double availableWidth,
  ) {
    const defaultDuration = Duration(minutes: 180);
    final totalDuration = state.visibleEnd.difference(state.visibleStart);

    if (event.endTime == null) {
      // Point events: show as small circle with text extending for 180 minutes
      final effectiveDuration = defaultDuration;
      final widthRatio =
          effectiveDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * availableWidth;
    } else {
      // Period events: show their actual duration as rectangle
      final actualDuration = event.endTime!.difference(event.startTime);
      final widthRatio =
          actualDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * availableWidth;
    }
  }

  double _getEventTextWidth(
    Event event,
    TimelineState state,
    double availableWidth,
  ) {
    const defaultDuration = Duration(minutes: 180);
    final totalDuration = state.visibleEnd.difference(state.visibleStart);

    if (event.endTime == null) {
      // Point events: text can use the full 180 minutes
      final effectiveDuration = defaultDuration;
      final widthRatio =
          effectiveDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * availableWidth;
    } else {
      // Period events: text can overflow up to 180 minutes total
      final actualDuration = event.endTime!.difference(event.startTime);
      final maxTextDuration =
          actualDuration.inMinutes < defaultDuration.inMinutes
          ? defaultDuration
          : actualDuration;

      final widthRatio =
          maxTextDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * availableWidth;
    }
  }
}
