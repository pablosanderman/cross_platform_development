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
  void initState() {
    super.initState();
    context.read<TimelineCubit>().loadTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hoist all repeated calculations to compute once
          final visibleWindow = state.visibleEnd.difference(state.visibleStart);
          final divisions = visibleWindow.inHours;
          final timelineWidth = divisions * TimelineConstants.pixelsPerHour;
          final timelineHeight =
              state.rows.length * TimelineConstants.rowHeight;

          return Column(
            children: [
              // Sticky ruler header
              Container(
                height: TimelineConstants.rulerHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: _buildStickyRuler(state, timelineWidth, divisions),
              ),
              // Timeline content with InteractiveViewer
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: TimelineConstants.minScale,
                  maxScale: TimelineConstants.maxScale,
                  constrained: false,
                  child: SizedBox(
                    width: timelineWidth,
                    height: timelineHeight,
                    child: Column(
                      children: _buildTimelineRows(
                        state,
                        timelineWidth,
                        visibleWindow,
                        divisions,
                      ),
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

  Widget _buildStickyRuler(
    TimelineState state,
    double timelineWidth,
    int divisions,
  ) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _transformationController,
        builder: (context, child) {
          // Get both translation and scale from the transformation matrix
          final matrix = _transformationController.value;
          final translation = matrix.getTranslation();
          final scale = matrix.getMaxScaleOnAxis();

          return SizedBox(
            height: TimelineConstants.rulerHeight,
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
                      height: TimelineConstants.rulerHeight,
                      child: _ColumnGrid(
                        divisions: divisions,
                        totalWidth: timelineWidth,
                        height: TimelineConstants.rulerHeight,
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
                      height: TimelineConstants.rulerHeight,
                      child: Row(
                        children: _buildRulerLabels(
                          state,
                          timelineWidth,
                          scale,
                          divisions,
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

  List<Widget> _buildRulerLabels(
    TimelineState state,
    double timelineWidth,
    double scale,
    int divisions,
  ) {
    final segmentWidth = timelineWidth * scale / divisions;

    return List.generate(divisions, (index) {
      String label;

      // Hour labels
      final segmentStart = state.visibleStart.add(Duration(hours: index));
      label =
          '${segmentStart.day}/${segmentStart.month} ${segmentStart.hour.toString().padLeft(2, '0')}:00';

      return SizedBox(
        width: segmentWidth,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: TimelineConstants.rulerFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildTimelineRows(
    TimelineState state,
    double timelineWidth,
    Duration visibleWindow,
    int divisions,
  ) {
    return state.rows.map((row) {
      return Container(
        height: TimelineConstants.rowHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Stack(
          children: [
            // Vertical grid lines behind events
            _ColumnGrid(
              divisions: divisions,
              totalWidth: timelineWidth,
              height: TimelineConstants.rowHeight,
            ),

            // Single loop over all events
            ...row.events.map((event) {
              final isGrouped = event.type == EventType.grouped;

              return _EventBox(
                event: event,
                state: state,
                timelineWidth: timelineWidth,
                visibleWindow: visibleWindow,
                isGrouped: isGrouped,
              );
            }),
          ],
        ),
      );
    }).toList();
  }
}

/// A widget that draws `divisions` vertical lines across `totalWidth`
class _ColumnGrid extends StatelessWidget {
  final int divisions;
  final double totalWidth;
  final double? height;

  const _ColumnGrid({
    required this.divisions,
    required this.totalWidth,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final columnWidth = totalWidth / divisions;
    return SizedBox(
      width: totalWidth,
      height: height,
      child: Row(
        children: List.generate(divisions, (index) {
          return Container(
            width: columnWidth,
            decoration: BoxDecoration(
              border: Border(
                right: index < divisions - 1
                    ? BorderSide(color: Colors.grey[300]!)
                    : BorderSide.none,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Unified event rendering widget that handles all event types
class _EventBox extends StatelessWidget {
  final Event event;
  final TimelineState state;
  final double timelineWidth;
  final Duration visibleWindow;
  final bool isGrouped;

  const _EventBox({
    required this.event,
    required this.state,
    required this.timelineWidth,
    required this.visibleWindow,
    required this.isGrouped,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor(event);

    // Handle grouped events specially
    if (isGrouped) {
      return _buildGroupedContents(color);
    }

    final isPeriodic = event.hasDuration;
    final Duration eventDuration = isPeriodic
        ? event.duration!
        : TimelineConstants.defaultEventDuration;

    final textWidth = _computeEventTextWidth(
      eventDuration: eventDuration,
      visibleWindow: visibleWindow,
      timelineWidth: timelineWidth,
    );

    return _wrapEventPosition(
      startTime: event.effectiveStartTime,
      state: state,
      timelineWidth: timelineWidth,
      visibleWindow: visibleWindow,
      child: SizedBox(
        width: textWidth,
        height: TimelineConstants.eventHeight,
        child: isPeriodic
            ? _buildPeriodContents(color, eventDuration)
            : _buildPointContents(color),
      ),
    );
  }

  Widget _buildGroupedContents(Color color) {
    if (event.members == null || event.members!.isEmpty) {
      // Fallback to regular rendering if no members
      return _buildPointContents(color);
    }

    final members = event.members!;
    final groupStart = event.effectiveStartTime;
    final groupEnd = event.effectiveEndTime!;

    // Calculate positions for all members relative to the visible timeline
    final memberPositions = members.map((member) {
      final memberOffset = member.timestamp.difference(state.visibleStart);
      final positionRatio =
          memberOffset.inMilliseconds / visibleWindow.inMilliseconds;
      return positionRatio * timelineWidth;
    }).toList();

    // Calculate the group's position relative to the visible timeline
    final groupStartOffset = groupStart.difference(state.visibleStart);
    final groupStartPosition =
        (groupStartOffset.inMilliseconds / visibleWindow.inMilliseconds) *
        timelineWidth;

    // Find the bounds of all member positions to create the border
    final minMemberPos = memberPositions.reduce((a, b) => a < b ? a : b);
    final maxMemberPos = memberPositions.reduce((a, b) => a > b ? a : b);

    // Add some padding around the members for the border
    const borderPadding = 8.0;
    final borderLeft = minMemberPos - borderPadding;
    final borderWidth =
        (maxMemberPos - minMemberPos) +
        (borderPadding * 2) +
        12; // +12 for circle size

    // Position the entire container at the leftmost member position
    const titlePadding = 120.0;
    final totalWidth = borderWidth + titlePadding;

    return Positioned(
      left: borderLeft,
      top: (TimelineConstants.rowHeight - TimelineConstants.eventHeight) / 2,
      child: SizedBox(
        width: totalWidth,
        height: TimelineConstants.eventHeight,
        child: Stack(
          children: [
            // Border around the grouped events
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: borderWidth,
                height: TimelineConstants.eventHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(4),
                  color: color.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Individual member events as small circles
            ...members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final absolutePosition = memberPositions[index];
              final relativePosition = absolutePosition - borderLeft;

              return Positioned(
                left: relativePosition,
                top: (TimelineConstants.eventHeight - 12) / 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              );
            }),
            // Title text to the right of the group
            Positioned(
              left: borderWidth + 8,
              top: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: TimelineConstants.fontSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointContents(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: TimelineConstants.eventHeight,
          height: TimelineConstants.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: TimelineConstants.eventOpacity),
            shape: BoxShape.circle,
            border: isGrouped ? Border.all(color: color, width: 2) : null,
          ),
          child: isGrouped
              ? Icon(Icons.group_work, size: 16, color: Colors.white)
              : null,
        ),
        SizedBox(width: TimelineConstants.eventSpacing),
        Expanded(
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: TimelineConstants.fontSize,
              fontWeight: isGrouped ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodContents(Color color, Duration eventDuration) {
    final fullWidth = _computeEventFullWidth(
      eventDuration: eventDuration,
      visibleWindow: visibleWindow,
      timelineWidth: timelineWidth,
    );

    return Stack(
      children: [
        Container(
          width: fullWidth,
          height: TimelineConstants.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: TimelineConstants.eventOpacity),
            borderRadius: BorderRadius.circular(
              TimelineConstants.eventBorderRadius,
            ),
            border: isGrouped ? Border.all(color: color, width: 2) : null,
          ),
        ),
        if (isGrouped)
          Positioned(
            left: 4,
            top: 4,
            child: Icon(Icons.group_work, size: 16, color: color),
          ),
        Positioned(
          left: isGrouped ? 24 : 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TimelineConstants.eventPadding,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: TimelineConstants.fontSize,
                  color: Colors.black87,
                  fontWeight: isGrouped ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getEventColor(Event event) {
    const eventColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    return eventColors[event.hashCode % eventColors.length].shade300;
  }

  double _computeEventTextWidth({
    required Duration eventDuration,
    required Duration visibleWindow,
    required double timelineWidth,
  }) {
    final maxTextSpan = eventDuration < TimelineConstants.defaultEventDuration
        ? TimelineConstants.defaultEventDuration
        : eventDuration;
    final ratio = maxTextSpan.inMilliseconds / visibleWindow.inMilliseconds;
    return ratio * timelineWidth;
  }

  double _computeEventFullWidth({
    required Duration eventDuration,
    required Duration visibleWindow,
    required double timelineWidth,
  }) {
    final ratio = eventDuration.inMilliseconds / visibleWindow.inMilliseconds;
    return ratio * timelineWidth;
  }

  Widget _wrapEventPosition({
    required DateTime startTime,
    required TimelineState state,
    required double timelineWidth,
    required Duration visibleWindow,
    required Widget child,
  }) {
    final eventOffset = startTime.difference(state.visibleStart);
    final positionRatio =
        eventOffset.inMilliseconds / visibleWindow.inMilliseconds;
    final leftOffset = positionRatio * timelineWidth;
    final verticalCenter =
        (TimelineConstants.rowHeight - TimelineConstants.eventHeight) / 2;

    return Positioned(left: leftOffset, top: verticalCenter, child: child);
  }
}
