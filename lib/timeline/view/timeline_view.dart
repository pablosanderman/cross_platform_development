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
  int? _draggedRowIndex;
  int? _dragTargetIndex;

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
              // Timeline content with drag and drop functionality
              Expanded(
                child: _DraggableTimelineContent(
                  rows: state.rows,
                  dimensions: dimensions,
                  transformationController: _transformationController,
                  draggedRowIndex: _draggedRowIndex,
                  dragTargetIndex: _dragTargetIndex,
                  onDragStarted: (index) {
                    setState(() {
                      _draggedRowIndex = index;
                    });
                  },
                  onDragEnded: () {
                    setState(() {
                      _draggedRowIndex = null;
                      _dragTargetIndex = null;
                    });
                  },
                  onDragAccepted: (draggedIndex, targetIndex) {
                    // Only perform reorder if targetIndex is valid (not -1)
                    if (targetIndex >= 0 && targetIndex != draggedIndex) {
                      context.read<TimelineCubit>().reorderRows(
                        draggedIndex,
                        targetIndex,
                      );
                    }
                    setState(() {
                      _draggedRowIndex = null;
                      _dragTargetIndex = null;
                    });
                  },
                  onDragTargetChanged: (index) {
                    setState(() {
                      _dragTargetIndex = index;
                    });
                  },
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
  final double memberCircleSize;
  final FontWeight pointEventFontWeight;
  final FontWeight periodEventFontWeight;
  final FontWeight groupEventFontWeight;

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
    required this.memberCircleSize,
    required this.pointEventFontWeight,
    required this.periodEventFontWeight,
    required this.groupEventFontWeight,
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
    const memberCircleSize = 16.0;

    // Font weights for different event types
    const pointEventFontWeight = FontWeight.w500;
    const periodEventFontWeight = FontWeight.w500;
    const groupEventFontWeight = FontWeight.w500;

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
      memberCircleSize: memberCircleSize,
      pointEventFontWeight: pointEventFontWeight,
      periodEventFontWeight: periodEventFontWeight,
      groupEventFontWeight: groupEventFontWeight,
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

/// Timeline content with animated rows during drag operations
class _AnimatedTimelineContent extends StatelessWidget {
  final List<TimelineRow> rows;
  final _TimelineDimensions dimensions;
  final TransformationController transformationController;
  final int? draggedRowIndex;
  final int? dragTargetIndex;

  const _AnimatedTimelineContent({
    required this.rows,
    required this.dimensions,
    required this.transformationController,
    required this.draggedRowIndex,
    required this.dragTargetIndex,
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
        child: Stack(children: _buildAnimatedRows()),
      ),
    );
  }

  List<Widget> _buildAnimatedRows() {
    final widgets = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      double topPosition = _calculateRowPosition(i);

      // Skip the dragged row - it's shown as feedback
      if (i == draggedRowIndex) {
        // Add placeholder gap where dragged row was
        widgets.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: 0,
            top: topPosition,
            right: 0,
            height: dimensions.rowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'Drop here',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: dimensions.fontSize,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      widgets.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          left: 0,
          top: topPosition,
          right: 0,
          height: dimensions.rowHeight,
          child: _TimelineRowWidget(row: row, dimensions: dimensions),
        ),
      );
    }

    return widgets;
  }

  double _calculateRowPosition(int index) {
    // Only animate if we have both a dragged row AND a valid drop target
    if (draggedRowIndex == null ||
        dragTargetIndex == null ||
        dragTargetIndex == -1) {
      return index * dimensions.rowHeight;
    }

    final draggedIndex = draggedRowIndex!;
    final targetIndex = dragTargetIndex!;

    // If dragging down (target > dragged)
    if (targetIndex > draggedIndex) {
      if (index <= draggedIndex) {
        // Rows above and including dragged stay in place
        return index * dimensions.rowHeight;
      } else if (index <= targetIndex) {
        // Rows between dragged and target move up
        return (index - 1) * dimensions.rowHeight;
      } else {
        // Rows below target stay in place
        return index * dimensions.rowHeight;
      }
    }
    // If dragging up (target < dragged)
    else if (targetIndex < draggedIndex) {
      if (index < targetIndex) {
        // Rows above target stay in place
        return index * dimensions.rowHeight;
      } else if (index < draggedIndex) {
        // Rows between target and dragged move down
        return (index + 1) * dimensions.rowHeight;
      } else {
        // Rows below and including dragged stay in place
        return index * dimensions.rowHeight;
      }
    }

    // Default case
    return index * dimensions.rowHeight;
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

    // Calculate positioning
    final leftOffset = _calculateLeftOffset();
    final verticalCenter = (dimensions.rowHeight - dimensions.eventHeight) / 2;

    // Handle grouped events specially
    if (isGrouped) {
      return Transform.translate(
        offset: Offset(leftOffset, verticalCenter),
        child: _GroupedEventWidget(
          event: event,
          dimensions: dimensions,
          color: color,
        ),
      );
    }

    final isPeriodic = event.hasDuration;
    final eventDuration = isPeriodic
        ? event.duration!
        : dimensions.defaultEventDuration;

    final textWidth = _computeEventTextWidth(eventDuration);

    return Transform.translate(
      offset: Offset(leftOffset, verticalCenter),
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

  double _calculateLeftOffset() {
    final isGrouped = event.type == EventType.grouped;

    // For grouped events, calculate the leftmost position based on all members
    if (isGrouped && event.members != null && event.members!.isNotEmpty) {
      final memberPositions = event.members!.map((member) {
        final memberOffset = member.timestamp.difference(
          dimensions.visibleStart,
        );
        return memberOffset.inHours * dimensions.pixelsPerHour;
      }).toList();

      final minMemberPos = memberPositions.reduce((a, b) => a < b ? a : b);
      final circleRadius = dimensions.memberCircleSize / 2;
      return minMemberPos - circleRadius; // Left edge of first circle
    }

    // For regular events
    final eventOffset = event.effectiveStartTime.difference(
      dimensions.visibleStart,
    );
    // Use the same calculation method as the grid: hours * pixelsPerHour
    final timestampPixelPosition =
        eventOffset.inHours * dimensions.pixelsPerHour;

    // For point events, center the circle on the timestamp
    final isPeriodic = event.hasDuration;
    return isPeriodic
        ? timestampPixelPosition
        : timestampPixelPosition -
              (dimensions.eventHeight / 2); // Center the circle
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
              fontWeight: dimensions.pointEventFontWeight,
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
                  fontWeight: dimensions.periodEventFontWeight,
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

    // Calculate container sizing based on member positions
    final circleRadius = dimensions.memberCircleSize / 2;
    final memberSpan = maxMemberPos - minMemberPos;
    const titlePadding = 120.0;
    final totalWidth = memberSpan + (circleRadius * 2) + titlePadding;

    return SizedBox(
      width: totalWidth,
      height: dimensions.eventHeight,
      child: Stack(
        children: [
          // Group horizontal lines (like equals sign) - only span timestamp range
          Positioned(
            left:
                circleRadius, // Offset by circle radius since container starts earlier
            child: _GroupHorizontalLines(
              width: maxMemberPos - minMemberPos, // Only timestamp range
              height: dimensions.eventHeight,
              color: color,
            ),
          ),
          // Member circles
          ..._buildMemberCircles(members, memberPositions),
          // Title - inline like other event types
          Positioned(
            left: memberSpan + (circleRadius * 2) + 8,
            top: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: dimensions.fontSize,
                  fontWeight: dimensions.groupEventFontWeight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMemberCircles(
    List<GroupMember> members,
    List<double> memberPositions,
  ) {
    final circleSize = dimensions.memberCircleSize;
    final minMemberPos = memberPositions.reduce((a, b) => a < b ? a : b);

    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final timestampPosition = memberPositions[index];
      // Position circles relative to the leftmost member position
      final relativePosition = timestampPosition - minMemberPos;

      return Positioned(
        left: relativePosition,
        top: (dimensions.eventHeight - circleSize) / 2,
        child: _MemberCircle(color: color, size: circleSize),
      );
    }).toList();
  }
}

/// Group horizontal lines widget (equals sign style)
class _GroupHorizontalLines extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _GroupHorizontalLines({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const lineThickness = 3.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Top horizontal line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: lineThickness, color: color),
          ),
          // Bottom horizontal line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: lineThickness, color: color),
          ),
          // Optional: Light background between the lines
          Positioned(
            top: lineThickness,
            bottom: lineThickness,
            left: 0,
            right: 0,
            child: Container(color: color.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }
}

/// Member circle widget
class _MemberCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _MemberCircle({required this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

/// Timeline content with drag and drop functionality
class _DraggableTimelineContent extends StatelessWidget {
  final List<TimelineRow> rows;
  final _TimelineDimensions dimensions;
  final TransformationController transformationController;
  final int? draggedRowIndex;
  final int? dragTargetIndex;
  final Function(int) onDragStarted;
  final VoidCallback onDragEnded;
  final Function(int, int) onDragAccepted;
  final Function(int) onDragTargetChanged;

  const _DraggableTimelineContent({
    required this.rows,
    required this.dimensions,
    required this.transformationController,
    required this.draggedRowIndex,
    required this.dragTargetIndex,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onDragAccepted,
    required this.onDragTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated timeline content with visual feedback
        _AnimatedTimelineContent(
          rows: rows,
          dimensions: dimensions,
          transformationController: transformationController,
          draggedRowIndex: draggedRowIndex,
          dragTargetIndex: dragTargetIndex,
        ),
        // Drag handles and drop targets that respond to transformation
        AnimatedBuilder(
          animation: transformationController,
          builder: (context, child) {
            final matrix = transformationController.value;
            final translation = matrix.getTranslation();
            final scale = matrix.getMaxScaleOnAxis();

            return Stack(
              children: [
                // Drop targets (behind drag handles) - reduced to avoid conflicts during animation
                if (draggedRowIndex != null)
                  ..._buildResponsiveDropTargets(
                    context,
                    translation.x,
                    translation.y,
                    scale,
                  ),
                // Floating drag handles (on top)
                ..._buildResponsiveDragHandles(
                  context,
                  translation.x,
                  translation.y,
                  scale,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildResponsiveDragHandles(
    BuildContext context,
    double translationX,
    double translationY,
    double scale,
  ) {
    final List<Widget> handles = [];

    for (int index = 0; index < rows.length; index++) {
      final isBeingDragged = draggedRowIndex == index;

      // Calculate row position after transformation
      final rowTop = index * dimensions.rowHeight;
      final transformedY = rowTop * scale + translationY;
      final handleY = transformedY + (dimensions.rowHeight * scale - 40) / 2;

      // Check if row is visible on screen
      final isVisible =
          transformedY > -dimensions.rowHeight * scale &&
          transformedY < MediaQuery.of(context).size.height;

      // Always create a positioned widget, but make it invisible if not visible
      handles.add(
        Positioned(
          key: ValueKey('drag_handle_$index'),
          left: 8.0, // Fixed position from left edge - no scaling
          top: handleY,
          child: Visibility(
            visible: isVisible,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (details) {
                final draggedIndex = details.data;
                // Accept drops on any row's handle
                if (draggedIndex == index) {
                  onDragTargetChanged(
                    -1,
                  ); // Reset target to indicate cancellation
                  return true;
                } else {
                  // Accept drops from other rows - treat as dropping on this row
                  onDragTargetChanged(index);
                  return true;
                }
              },
              onAcceptWithDetails: (details) {
                final draggedIndex = details.data;
                if (draggedIndex == index) {
                  // Same row drop on handle - cancel the drag
                  onDragEnded();
                  return;
                } else {
                  // Different row drop on handle - perform the reorder
                  onDragAccepted(draggedIndex, index);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return GestureDetector(
                  onTap: () {
                    // Drag handle tap (optional: could add functionality here)
                  },
                  child: Draggable<int>(
                    data: index,
                    feedback: _DragFeedback(
                      row: rows[index],
                      dimensions: dimensions,
                      transformationController: transformationController,
                    ),
                    childWhenDragging: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onDragStarted: () {
                      onDragStarted(index);
                    },
                    onDragEnd: (_) {
                      onDragEnded();
                    },
                    child: _DragHandle(
                      isBeingDragged: isBeingDragged,
                      dimensions: dimensions,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return handles;
  }

  List<Widget> _buildResponsiveDropTargets(
    BuildContext context,
    double translationX,
    double translationY,
    double scale,
  ) {
    final List<Widget> targets = [];

    for (int index = 0; index < rows.length; index++) {
      final isDragging = draggedRowIndex != null;

      // Calculate row position after transformation
      final rowTop = index * dimensions.rowHeight;
      final transformedY = rowTop * scale + translationY;
      final transformedHeight = dimensions.rowHeight * scale;

      // Check if row is visible on screen
      final isVisible =
          transformedY > -transformedHeight &&
          transformedY < MediaQuery.of(context).size.height;

      // Always create a positioned widget, but control visibility and interaction
      targets.add(
        Positioned(
          key: ValueKey('drop_target_$index'),
          left: 0,
          top: transformedY,
          right: 0,
          height: transformedHeight,
          child: Visibility(
            visible: isVisible || isDragging,
            child: IgnorePointer(
              ignoring:
                  !isDragging, // Only accept gestures when actively dragging
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) {
                  final draggedIndex = details.data;
                  if (draggedIndex != index) {
                    onDragTargetChanged(index);
                    return true;
                  }
                  return true; // Accept same-row drops to ensure cleanup
                },
                onAcceptWithDetails: (details) {
                  final draggedIndex = details.data;
                  if (draggedIndex == index) {
                    // Same row drop - manually trigger cleanup since onDragEnd won't be called
                    onDragEnded(); // Call the parent's cleanup callback
                    return;
                  }
                  onDragAccepted(draggedIndex, index);
                },
                onLeave: (_) {
                  onDragTargetChanged(-1);
                },
                builder: (context, candidateData, rejectedData) {
                  final isHighlighted =
                      dragTargetIndex == index &&
                      draggedRowIndex != null &&
                      draggedRowIndex != index;
                  return Container(
                    height: transformedHeight,
                    decoration: isHighlighted
                        ? BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.blue, width: 2),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return targets;
  }
}

/// Drag handle widget
class _DragHandle extends StatelessWidget {
  final bool isBeingDragged;
  final _TimelineDimensions dimensions;

  const _DragHandle({required this.isBeingDragged, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isBeingDragged
            ? Colors.blue.withValues(alpha: 0.8)
            : Colors.grey[600]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.drag_handle, color: Colors.white, size: 18),
    );
  }
}

/// Drag feedback widget shown during dragging
class _DragFeedback extends StatelessWidget {
  final TimelineRow row;
  final _TimelineDimensions dimensions;
  final TransformationController transformationController;

  const _DragFeedback({
    required this.row,
    required this.dimensions,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    // Get current transformation
    final matrix = transformationController.value;
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();

    // Calculate what part of the timeline is currently visible on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final visibleTimelineStart =
        -translation.x / scale; // Left edge of visible area in timeline coords
    final visibleTimelineWidth =
        screenWidth / scale; // Width of visible area in timeline coords
    final visibleTimelineEnd = visibleTimelineStart + visibleTimelineWidth;

    // Create a preview showing only the visible portion at current scale
    final previewWidth = screenWidth * 0.8;
    final previewHeight =
        dimensions.rowHeight * scale; // Scale the height to match zoom

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: Transform.scale(
        scale: 0.95,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Background grid (similar to timeline)
                  Container(
                    width: previewWidth,
                    height: previewHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  // Show events that are visible in current viewport with proper scaling
                  ...row.events
                      .where((event) {
                        final eventStart =
                            event.effectiveStartTime
                                .difference(dimensions.visibleStart)
                                .inHours *
                            dimensions.pixelsPerHour;
                        final eventEnd =
                            eventStart +
                            (event.hasDuration
                                ? event.duration!.inHours *
                                      dimensions.pixelsPerHour
                                : dimensions.defaultEventDuration.inHours *
                                      dimensions.pixelsPerHour);

                        // Check if event overlaps with visible area
                        return eventEnd > visibleTimelineStart &&
                            eventStart < visibleTimelineEnd;
                      })
                      .map((event) {
                        // Calculate event position relative to visible area
                        final eventStart =
                            event.effectiveStartTime
                                .difference(dimensions.visibleStart)
                                .inHours *
                            dimensions.pixelsPerHour;
                        final relativeStart = eventStart - visibleTimelineStart;

                        // Scale to preview size and position
                        final previewStart =
                            (relativeStart / visibleTimelineWidth) *
                            previewWidth;

                        // Create dimensions that match the current zoom level
                        final scaledDimensions = _TimelineDimensions._(
                          visibleStart: dimensions.visibleStart,
                          visibleEnd: dimensions.visibleEnd,
                          visibleWindow: dimensions.visibleWindow,
                          divisions: dimensions.divisions,
                          timelineWidth: dimensions.timelineWidth * scale,
                          timelineHeight: dimensions.timelineHeight * scale,
                          pixelsPerHour: dimensions.pixelsPerHour * scale,
                          rowHeight: dimensions.rowHeight * scale,
                          eventHeight: dimensions.eventHeight * scale,
                          rulerHeight: dimensions.rulerHeight,
                          fontSize: dimensions.fontSize,
                          rulerFontSize: dimensions.rulerFontSize,
                          eventSpacing: dimensions.eventSpacing * scale,
                          eventPadding: dimensions.eventPadding * scale,
                          eventBorderRadius: dimensions.eventBorderRadius,
                          eventOpacity: dimensions.eventOpacity,
                          minScale: dimensions.minScale,
                          maxScale: dimensions.maxScale,
                          defaultEventDuration: dimensions.defaultEventDuration,
                          memberCircleSize: dimensions.memberCircleSize * scale,
                          pointEventFontWeight: dimensions.pointEventFontWeight,
                          periodEventFontWeight:
                              dimensions.periodEventFontWeight,
                          groupEventFontWeight: dimensions.groupEventFontWeight,
                        );

                        return Positioned(
                          left: previewStart,
                          top:
                              (previewHeight - scaledDimensions.eventHeight) /
                              2, // Properly center vertically
                          child: Transform.scale(
                            scale:
                                (previewWidth / visibleTimelineWidth) /
                                scale, // Adjust for preview scaling
                            alignment: Alignment.centerLeft,
                            child: _EventBox(
                              event: event,
                              dimensions: scaledDimensions,
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
