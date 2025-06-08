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

          // Calculate consistent dimensions based on time and content
          final dimensions = _TimelineDimensions.calculate(
            visibleStart: state.visibleStart,
            visibleEnd: state.visibleEnd,
            rowCount: state.rows.length,
          );

          return Column(
            children: [
              // Sticky ruler header
              _StickyRuler(
                dimensions: dimensions,
                transformationController: _transformationController,
              ),
              // Timeline content with InteractiveViewer
              Expanded(
                child: _TimelineContent(
                  rows: state.rows,
                  dimensions: dimensions,
                  transformationController: _transformationController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Responsive dimensions calculator for timeline
class _TimelineDimensions {
  final DateTime visibleStart;
  final DateTime visibleEnd;
  final Duration visibleWindow;
  final int divisions;
  final double timelineWidth;
  final double timelineHeight;
  final double pixelsPerHour;

  // Calculated responsive dimensions
  final double rowHeight;
  final double eventHeight;
  final double rulerHeight;
  final double fontSize;
  final double rulerFontSize;
  final double eventSpacing;
  final double eventPadding;
  final double eventBorderRadius;
  final double eventOpacity;
  final double minScale;
  final double maxScale;
  final Duration defaultEventDuration;

  _TimelineDimensions._({
    required this.visibleStart,
    required this.visibleEnd,
    required this.visibleWindow,
    required this.divisions,
    required this.timelineWidth,
    required this.timelineHeight,
    required this.pixelsPerHour,
    required this.rowHeight,
    required this.eventHeight,
    required this.rulerHeight,
    required this.fontSize,
    required this.rulerFontSize,
    required this.eventSpacing,
    required this.eventPadding,
    required this.eventBorderRadius,
    required this.eventOpacity,
    required this.minScale,
    required this.maxScale,
    required this.defaultEventDuration,
  });

  static _TimelineDimensions calculate({
    required DateTime visibleStart,
    required DateTime visibleEnd,
    required int rowCount,
  }) {
    final visibleWindow = visibleEnd.difference(visibleStart);
    final divisions = visibleWindow.inHours;

    // Calculate timeline width based on optimal readability
    // Use a base density that provides good readability for event titles and positioning
    const baseDensityPixelsPerHour =
        120.0; // Reasonable base for most use cases
    final timelineWidth = divisions * baseDensityPixelsPerHour;
    final pixelsPerHour = baseDensityPixelsPerHour;

    // Use consistent, well-proportioned dimensions
    const rowHeight = 75.0;
    const eventHeight = 45.0; // 60% of row height
    const rulerHeight = 55.0;

    // Consistent typography
    const fontSize = 13.0;
    const rulerFontSize = 11.0;

    // Consistent spacing
    const eventSpacing = 8.0;
    const eventPadding = 10.0;
    const eventBorderRadius = 4.0;

    // Timeline height based on row count
    final timelineHeight = rowCount * rowHeight;

    return _TimelineDimensions._(
      visibleStart: visibleStart,
      visibleEnd: visibleEnd,
      visibleWindow: visibleWindow,
      divisions: divisions,
      timelineWidth: timelineWidth,
      timelineHeight: timelineHeight,
      pixelsPerHour: pixelsPerHour,
      rowHeight: rowHeight,
      eventHeight: eventHeight,
      rulerHeight: rulerHeight,
      fontSize: fontSize,
      rulerFontSize: rulerFontSize,
      eventSpacing: eventSpacing,
      eventPadding: eventPadding,
      eventBorderRadius: eventBorderRadius,
      eventOpacity: 0.9,
      minScale: 0.2,
      maxScale: 4.0,
      defaultEventDuration: const Duration(hours: 2),
    );
  }
}

/// Sticky ruler header component
class _StickyRuler extends StatelessWidget {
  final _TimelineDimensions dimensions;
  final TransformationController transformationController;

  const _StickyRuler({
    required this.dimensions,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dimensions.rulerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: transformationController,
          builder: (context, child) {
            // Get both translation and scale from the transformation matrix
            final matrix = transformationController.value;
            final translation = matrix.getTranslation();
            final scale = matrix.getMaxScaleOnAxis();

            return SizedBox(
              height: dimensions.rulerHeight,
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
                        width: dimensions.timelineWidth,
                        height: dimensions.rulerHeight,
                        child: _RulerGrid(
                          divisions: dimensions.divisions,
                          totalWidth: dimensions.timelineWidth,
                          height: dimensions.rulerHeight,
                        ),
                      ),
                    ),
                  ),
                  // Non-scaled text overlay
                  Transform(
                    transform: Matrix4.identity()
                      ..translate(translation.x, 0.0),
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: SizedBox(
                        width: dimensions.timelineWidth * scale,
                        height: dimensions.rulerHeight,
                        child: _RulerLabels(
                          dimensions: dimensions,
                          scale: scale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Timeline content with InteractiveViewer
class _TimelineContent extends StatelessWidget {
  final List<TimelineRow> rows;
  final _TimelineDimensions dimensions;
  final TransformationController transformationController;

  const _TimelineContent({
    required this.rows,
    required this.dimensions,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformationController,
      minScale: dimensions.minScale,
      maxScale: dimensions.maxScale,
      constrained: false,
      child: SizedBox(
        width: dimensions.timelineWidth,
        height: dimensions.timelineHeight,
        child: Column(
          children: rows
              .map(
                (row) => _TimelineRowWidget(row: row, dimensions: dimensions),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Ruler grid component
class _RulerGrid extends StatelessWidget {
  final int divisions;
  final double totalWidth;
  final double height;

  const _RulerGrid({
    required this.divisions,
    required this.totalWidth,
    required this.height,
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

/// Ruler labels component
class _RulerLabels extends StatelessWidget {
  final _TimelineDimensions dimensions;
  final double scale;

  const _RulerLabels({required this.dimensions, required this.scale});

  @override
  Widget build(BuildContext context) {
    final totalWidth = dimensions.timelineWidth * scale;
    final segmentWidth = totalWidth / dimensions.divisions;

    return Row(
      children: List.generate(dimensions.divisions, (index) {
        final segmentStart = dimensions.visibleStart.add(
          Duration(hours: index),
        );
        final label =
            '${segmentStart.day}/${segmentStart.month} ${segmentStart.hour.toString().padLeft(2, '0')}:00';

        // For the last segment, use Expanded to take remaining space
        // to avoid floating point precision issues
        if (index == dimensions.divisions - 1) {
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: dimensions.rulerFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: segmentWidth,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: dimensions.rulerFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Timeline row widget
class _TimelineRowWidget extends StatelessWidget {
  final TimelineRow row;
  final _TimelineDimensions dimensions;

  const _TimelineRowWidget({required this.row, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: dimensions.rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Stack(
        children: [
          // Vertical grid lines behind events
          _RulerGrid(
            divisions: dimensions.divisions,
            totalWidth: dimensions.timelineWidth,
            height: dimensions.rowHeight,
          ),
          // Event boxes
          ...row.events.map(
            (event) => _EventBox(event: event, dimensions: dimensions),
          ),
        ],
      ),
    );
  }
}

/// Event display component
class _EventBox extends StatelessWidget {
  final Event event;
  final _TimelineDimensions dimensions;

  const _EventBox({required this.event, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor(event);
    final isGrouped = event.type == EventType.grouped;

    // Handle grouped events specially
    if (isGrouped) {
      return _GroupedEventWidget(
        event: event,
        dimensions: dimensions,
        color: color,
      );
    }

    final isPeriodic = event.hasDuration;
    final eventDuration = isPeriodic
        ? event.duration!
        : dimensions.defaultEventDuration;

    final textWidth = _computeEventTextWidth(eventDuration);

    return _wrapEventPosition(
      child: SizedBox(
        width: textWidth,
        height: dimensions.eventHeight,
        child: isPeriodic
            ? _PeriodEventWidget(
                event: event,
                color: color,
                eventDuration: eventDuration,
                dimensions: dimensions,
              )
            : _PointEventWidget(
                event: event,
                color: color,
                dimensions: dimensions,
              ),
      ),
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

  double _computeEventTextWidth(Duration eventDuration) {
    final maxTextSpan = eventDuration < dimensions.defaultEventDuration
        ? dimensions.defaultEventDuration
        : eventDuration;
    // Use the same calculation method as the grid: hours * pixelsPerHour
    return maxTextSpan.inHours * dimensions.pixelsPerHour;
  }

  Widget _wrapEventPosition({required Widget child}) {
    final eventOffset = event.effectiveStartTime.difference(
      dimensions.visibleStart,
    );
    // Use the same calculation method as the grid: hours * pixelsPerHour
    final leftOffset = eventOffset.inHours * dimensions.pixelsPerHour;
    final verticalCenter = (dimensions.rowHeight - dimensions.eventHeight) / 2;

    return Positioned(left: leftOffset, top: verticalCenter, child: child);
  }
}

/// Point event widget (circular event)
class _PointEventWidget extends StatelessWidget {
  final Event event;
  final Color color;
  final _TimelineDimensions dimensions;

  const _PointEventWidget({
    required this.event,
    required this.color,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dimensions.eventHeight,
          height: dimensions.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dimensions.eventOpacity),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: dimensions.eventSpacing),
        Expanded(
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: dimensions.fontSize,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Period event widget (rectangular event with duration)
class _PeriodEventWidget extends StatelessWidget {
  final Event event;
  final Color color;
  final Duration eventDuration;
  final _TimelineDimensions dimensions;

  const _PeriodEventWidget({
    required this.event,
    required this.color,
    required this.eventDuration,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = _computeEventFullWidth();

    return Stack(
      children: [
        Container(
          width: fullWidth,
          height: dimensions.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dimensions.eventOpacity),
            borderRadius: BorderRadius.circular(dimensions.eventBorderRadius),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dimensions.eventPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: dimensions.fontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _computeEventFullWidth() {
    // Use the same calculation method as the grid: hours * pixelsPerHour
    return eventDuration.inHours * dimensions.pixelsPerHour;
  }
}

/// Grouped event widget (shows multiple related events)
class _GroupedEventWidget extends StatelessWidget {
  final Event event;
  final _TimelineDimensions dimensions;
  final Color color;

  const _GroupedEventWidget({
    required this.event,
    required this.dimensions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (event.members == null || event.members!.isEmpty) {
      return _PointEventWidget(
        event: event,
        color: color,
        dimensions: dimensions,
      );
    }

    final members = event.members!;
    final memberPositions = members.map((member) {
      final memberOffset = member.timestamp.difference(dimensions.visibleStart);
      // Use the same calculation method as the grid: hours * pixelsPerHour
      return memberOffset.inHours * dimensions.pixelsPerHour;
    }).toList();

    final minMemberPos = memberPositions.reduce((a, b) => a < b ? a : b);
    final maxMemberPos = memberPositions.reduce((a, b) => a > b ? a : b);

    const borderPadding = 8.0;
    final borderLeft = minMemberPos - borderPadding;
    final borderWidth =
        (maxMemberPos - minMemberPos) + (borderPadding * 2) + 12;
    const titlePadding = 120.0;
    final totalWidth = borderWidth + titlePadding;

    return Positioned(
      left: borderLeft,
      top: (dimensions.rowHeight - dimensions.eventHeight) / 2,
      child: SizedBox(
        width: totalWidth,
        height: dimensions.eventHeight,
        child: Stack(
          children: [
            // Group border
            _GroupBorder(
              width: borderWidth,
              height: dimensions.eventHeight,
              color: color,
            ),
            // Member circles
            ..._buildMemberCircles(members, memberPositions, borderLeft),
            // Title
            _GroupTitle(
              event: event,
              borderWidth: borderWidth,
              color: color,
              dimensions: dimensions,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMemberCircles(
    List<GroupMember> members,
    List<double> memberPositions,
    double borderLeft,
  ) {
    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final absolutePosition = memberPositions[index];
      final relativePosition = absolutePosition - borderLeft;

      return Positioned(
        left: relativePosition,
        top: (dimensions.eventHeight - 12) / 2,
        child: _MemberCircle(color: color),
      );
    }).toList();
  }
}

/// Group border widget
class _GroupBorder extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _GroupBorder({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
    );
  }
}

/// Member circle widget
class _MemberCircle extends StatelessWidget {
  final Color color;

  const _MemberCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

/// Group title widget
class _GroupTitle extends StatelessWidget {
  final Event event;
  final double borderWidth;
  final Color color;
  final _TimelineDimensions dimensions;

  const _GroupTitle({
    required this.event,
    required this.borderWidth,
    required this.color,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: borderWidth + 8,
      top: 0,
      right: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          event.title,
          style: TextStyle(
            fontSize: dimensions.fontSize,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
