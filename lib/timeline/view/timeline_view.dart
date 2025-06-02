import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/timeline/models/models.dart';

/// {@template timeline_view}
/// A [StatelessWidget] which reacts to the provided
/// [TimelineCubit] state and notifies it in response to user input.
/// {@endtemplate}
class TimelineView extends StatefulWidget {
  /// {@macro timeline_view}
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<TimelineCubit>().loadTimeline();
    return Scaffold(
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final timelineWidth = _calculateTimelineWidth(state);
          final timelineHeight = _calculateTimelineHeight(state);

          return Column(
            children: [
              // Sticky ruler header
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: _buildStickyRuler(state, timelineWidth),
              ),
              // Timeline content with InteractiveViewer
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.3,
                  maxScale: 3.0,
                  constrained: false,
                  child: SizedBox(
                    width: timelineWidth,
                    height: timelineHeight,
                    child: Column(
                      children: _buildTimelineRows(state, timelineWidth),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateTimelineWidth(TimelineState state) {
    final duration = state.visibleDuration;

    // Debug information
    print(
      'Timeline duration: ${duration.inHours} hours (${duration.inDays} days)',
    );
    print('Visible start: ${state.visibleStart}');
    print('Visible end: ${state.visibleEnd}');

    // Calculate width based on duration and desired pixels per hour
    if (duration.inDays < 2) {
      // For hour ruler: 120 pixels per hour for good spacing
      final width = duration.inHours * 120.0;
      print('Calculated timeline width: ${width}px');
      return width;
    } else if (duration.inDays < 14) {
      // For day ruler: 150 pixels per day
      final width = duration.inDays * 150.0;
      print('Calculated timeline width: ${width}px');
      return width;
    } else if (duration.inDays < 90) {
      // For week ruler: 200 pixels per week
      final width = (duration.inDays / 7) * 200.0;
      print('Calculated timeline width: ${width}px');
      return width;
    } else if (duration.inDays < 730) {
      // For month ruler: 250 pixels per month
      final months =
          ((state.visibleEnd.year - state.visibleStart.year) * 12 +
          state.visibleEnd.month -
          state.visibleStart.month);
      final width = months * 250.0;
      print('Calculated timeline width: ${width}px');
      return width;
    } else {
      // For year ruler: 300 pixels per year
      final years = state.visibleEnd.year - state.visibleStart.year + 1;
      final width = years * 300.0;
      print('Calculated timeline width: ${width}px');
      return width;
    }
  }

  double _calculateTimelineHeight(TimelineState state) {
    return state.rows.length * 80.0; // 80px per row
  }

  Widget _buildStickyRuler(TimelineState state, double timelineWidth) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _transformationController,
        builder: (context, child) {
          // Get both translation and scale from the transformation matrix
          final matrix = _transformationController.value;
          final translation = matrix.getTranslation();
          final scale = matrix.getMaxScaleOnAxis();

          return SizedBox(
            height: 60,
            child: Stack(
              children: [
                // Scaled ruler structure (borders and segments)
                Transform(
                  transform: Matrix4.identity()
                    ..translate(translation.x, 0.0)
                    ..scale(scale, 1.0),
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: SizedBox(
                      width: timelineWidth,
                      height: 60,
                      child: Row(
                        children: _buildRulerStructure(state, timelineWidth),
                      ),
                    ),
                  ),
                ),
                // Non-scaled text overlay
                Transform(
                  transform: Matrix4.identity()..translate(translation.x, 0.0),
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: SizedBox(
                      width: timelineWidth * scale,
                      height: 60,
                      child: Row(
                        children: _buildRulerLabels(
                          state,
                          timelineWidth,
                          scale,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRulerStructure(TimelineState state, double timelineWidth) {
    final duration = state.visibleDuration;
    int divisions;

    if (duration.inDays < 2) {
      divisions = duration.inHours;
    } else if (duration.inDays < 14) {
      divisions = duration.inDays;
    } else if (duration.inDays < 90) {
      divisions = (duration.inDays / 7).ceil();
    } else if (duration.inDays < 730) {
      divisions =
          ((state.visibleEnd.year - state.visibleStart.year) * 12 +
          state.visibleEnd.month -
          state.visibleStart.month);
    } else {
      divisions = state.visibleEnd.year - state.visibleStart.year + 1;
    }

    final segmentWidth = timelineWidth / divisions;

    return List.generate(divisions, (index) {
      return Container(
        width: segmentWidth,
        decoration: BoxDecoration(
          border: Border(
            right: index < divisions - 1
                ? BorderSide(color: Colors.grey[300]!)
                : BorderSide.none,
          ),
        ),
      );
    });
  }

  List<Widget> _buildRulerLabels(
    TimelineState state,
    double timelineWidth,
    double scale,
  ) {
    final duration = state.visibleDuration;
    final start = state.visibleStart;
    final end = state.visibleEnd;
    int divisions;

    if (duration.inDays < 2) {
      divisions = duration.inHours;
    } else if (duration.inDays < 14) {
      divisions = duration.inDays;
    } else if (duration.inDays < 90) {
      divisions = (duration.inDays / 7).ceil();
    } else if (duration.inDays < 730) {
      divisions = ((end.year - start.year) * 12 + end.month - start.month);
    } else {
      divisions = end.year - start.year + 1;
    }

    final segmentWidth = timelineWidth * scale / divisions;

    return List.generate(divisions, (index) {
      String label;

      if (duration.inDays < 2) {
        // Hour labels
        final segmentStart = start.add(Duration(hours: index));
        label =
            '${segmentStart.day}/${segmentStart.month} ${segmentStart.hour.toString().padLeft(2, '0')}:00';
      } else if (duration.inDays < 14) {
        // Day labels
        final segmentStart = start.add(Duration(days: index));
        label = '${segmentStart.day}/${segmentStart.month}';
      } else if (duration.inDays < 90) {
        // Week labels
        final segmentStart = start.add(Duration(days: index * 7));
        label = 'W${_getWeekOfYear(segmentStart)}';
      } else if (duration.inDays < 730) {
        // Month labels
        final segmentDate = DateTime(start.year, start.month + index);
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
        label = monthNames[segmentDate.month - 1];
      } else {
        // Year labels
        final segmentYear = start.year + index;
        label = segmentYear.toString();
      }

      return Container(
        width: segmentWidth,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: duration.inDays < 2 ? 12 : 14,
              fontWeight: FontWeight.w500,
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

  List<Widget> _buildTimelineRows(TimelineState state, double timelineWidth) {
    return state.rows.map((row) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Stack(
          children: [
            // Vertical grid lines behind events
            _buildGridLines(state, timelineWidth),
            // Events on top of grid lines
            ...row.events.map((event) {
              return _buildEventWidget(event, state, timelineWidth);
            }),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildGridLines(TimelineState state, double timelineWidth) {
    final duration = state.visibleDuration;
    int divisions;

    if (duration.inDays < 2) {
      divisions = duration.inHours;
    } else if (duration.inDays < 14) {
      divisions = duration.inDays;
    } else if (duration.inDays < 90) {
      divisions = (duration.inDays / 7).ceil();
    } else if (duration.inDays < 730) {
      divisions =
          ((state.visibleEnd.year - state.visibleStart.year) * 12 +
          state.visibleEnd.month -
          state.visibleStart.month);
    } else {
      divisions = state.visibleEnd.year - state.visibleStart.year + 1;
    }

    return Row(
      children: List.generate(divisions, (columnIndex) {
        return Container(
          width: timelineWidth / divisions,
          decoration: BoxDecoration(
            border: Border(
              right: columnIndex < divisions - 1
                  ? BorderSide(color: Colors.grey[300]!)
                  : BorderSide.none,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEventWidget(
    Event event,
    TimelineState state,
    double timelineWidth,
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
    final leftOffset = _getEventPosition(event.startTime, state, timelineWidth);
    final width = _getEventWidth(event, state, timelineWidth);
    final textWidth = _getEventTextWidth(event, state, timelineWidth);

    // Calculate vertical center position dynamically
    const rowHeight = 80.0;
    const eventHeight = 50.0;
    const opacity = 0.97;
    const fontSize = 14.0;
    final verticalCenter = (rowHeight - eventHeight) / 2;

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
                  style: const TextStyle(fontSize: fontSize),
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
          width: textWidth,
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
    double timelineWidth,
  ) {
    // Calculate position based on time relative to visible timeline
    final totalDuration = state.visibleEnd.difference(state.visibleStart);
    final eventOffset = eventTime.difference(state.visibleStart);

    // Calculate position as a ratio of the timeline, then scale to timeline width
    final positionRatio =
        eventOffset.inMilliseconds / totalDuration.inMilliseconds;
    return positionRatio * timelineWidth;
  }

  double _getEventWidth(
    Event event,
    TimelineState state,
    double timelineWidth,
  ) {
    const defaultDuration = Duration(minutes: 180);
    final totalDuration = state.visibleEnd.difference(state.visibleStart);

    if (event.endTime == null) {
      // Point events: show as small circle with text extending for 180 minutes
      final effectiveDuration = defaultDuration;
      final widthRatio =
          effectiveDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * timelineWidth;
    } else {
      // Period events: show their actual duration as rectangle
      final actualDuration = event.endTime!.difference(event.startTime);
      final widthRatio =
          actualDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * timelineWidth;
    }
  }

  double _getEventTextWidth(
    Event event,
    TimelineState state,
    double timelineWidth,
  ) {
    const defaultDuration = Duration(minutes: 180);
    final totalDuration = state.visibleEnd.difference(state.visibleStart);

    if (event.endTime == null) {
      // Point events: text can use the full 180 minutes
      final effectiveDuration = defaultDuration;
      final widthRatio =
          effectiveDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * timelineWidth;
    } else {
      // Period events: text can overflow up to 180 minutes total
      final actualDuration = event.endTime!.difference(event.startTime);
      final maxTextDuration =
          actualDuration.inMinutes < defaultDuration.inMinutes
          ? defaultDuration
          : actualDuration;

      final widthRatio =
          maxTextDuration.inMilliseconds / totalDuration.inMilliseconds;
      return widthRatio * timelineWidth;
    }
  }
}
