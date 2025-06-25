import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/map/map.dart';
import 'package:cross_platform_development/shared/shared.dart';
import '../../comparison/comparison.dart';
import 'package:cross_platform_development/navigation/navigation.dart';

import '../../widgets/add_event/add_event_overlay.dart';

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

class _TimelineViewState extends State<TimelineView>
    with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  int? _draggedRowIndex;
  int? _dragTargetIndex;
  AnimationController? _scrollAnimationController;
  double _actualTimelineWidth = 0.0;
  TimelineCubit? _timelineCubit;
  bool _showAddEventOverlay = false; // Controls visibility of the add-event widget

  @override
  void initState() {
    super.initState();

    // Store reference to cubit to avoid unsafe context access in dispose
    _timelineCubit = context.read<TimelineCubit>();

    // Initialize transformation controller with saved state or identity matrix
    final savedMatrix = _timelineCubit!.getSavedTransformationMatrix();
    _transformationController = TransformationController(
      savedMatrix ?? Matrix4.identity(),
    );

    // Listen to transformation changes and save them to cubit
    _transformationController.addListener(() {
      _timelineCubit!.saveTransformationMatrix(_transformationController.value);
    });

    // Load timeline events only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timelineCubit!.state.events.isEmpty) {
        _timelineCubit!.loadTimeline();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocListener<TimelineCubit, TimelineState>(
            listenWhen: (previous, current) =>
                current.scrollToEvent != null &&
                previous.scrollToEvent != current.scrollToEvent,
            listener: (context, state) {
              if (state.scrollToEvent != null) {
                _scrollToEventAnimated(state.scrollToEvent!, state);
            // Clear the scroll event after handling
                _timelineCubit!.clearScrollToEvent();
              }
            },
            child: BlocBuilder<TimelineCubit, TimelineState>(
              builder: (context, state) {
                if (state.rows.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

            // Calculate consistent dimensions based on time and content
                final dimensions = _TimelineDimensions.calculate(
                  visibleStart: state.visibleStart,
                  visibleEnd: state.visibleEnd,
                  rows: state.rows,
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
                        actualTimelineWidth: _actualTimelineWidth,
                        onDragStarted: (index) {
                          setState(() => _draggedRowIndex = index);
                        },
                        onDragEnded: () {
                          setState(() {
                            _draggedRowIndex = null;
                            _dragTargetIndex = null;
                          });
                        },
                        onDragAccepted: (draggedIndex, targetIndex) {
                          if (targetIndex >= 0 && targetIndex != draggedIndex) {
                            _timelineCubit!.reorderRows(draggedIndex, targetIndex);
                          }
                          setState(() {
                            _draggedRowIndex = null;
                            _dragTargetIndex = null;
                          });
                        },
                        onDragTargetChanged: (index) {
                          setState(() => _dragTargetIndex = index);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Overlay Add Event Form
          if (_showAddEventOverlay)
            AddEventOverlay(
              onSubmitted: (eventData) {
                setState(() => _showAddEventOverlay = false);
                if (eventData != null) {
                  _timelineCubit!.addEvent(
                    eventData['title'],
                    eventData['description'],
                    eventData['startTime'],
                    eventData['endTime'],
                    eventData['latitude'],
                    eventData['longitude'],
                  );
                  // Pass other data if extending `addEvent` in the cubit.
                }
              },
              onCancel: () => setState(() => _showAddEventOverlay = false),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () => setState(() => _showAddEventOverlay = true),
            ),
          ),
        ],
      ),
    );
  }
  /// Animate the timeline to show a specific event
  void _scrollToEventAnimated(Event event, TimelineState state) {
    // Calculate dimensions to get pixel positions
    final dimensions = _TimelineDimensions.calculate(
      visibleStart: state.visibleStart,
      visibleEnd: state.visibleEnd,
      rows: state.rows,
    );

    // Calculate event position in timeline coordinates
    final eventOffset = event.effectiveStartTime.difference(
      dimensions.visibleStart,
    );
    final eventPixelPosition = eventOffset.inHours * dimensions.pixelsPerHour;

    // Get current transformation values
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final currentTranslation = currentMatrix.getTranslation();

    // Get the actual viewport width available to the timeline (accounts for split screen)
    final currentViewportWidth = _actualTimelineWidth > 0
        ? _actualTimelineWidth
        : MediaQuery.of(context).size.width;

    // Calculate target screen position (1/3 from left edge for visual balance)
    final targetScreenPosition = currentViewportWidth * (1 / 3);

    // Calculate correct translation using transformation matrix mathematics:
    // screen_x = (timeline_x × scale) + translation_x
    // Therefore: translation_x = screen_x - (timeline_x × scale)
    final targetTranslationX =
        targetScreenPosition - (eventPixelPosition * currentScale);

    // Create target transformation matrix preserving current scale and vertical position
    final targetMatrix = Matrix4.identity()
      ..translate(targetTranslationX, currentTranslation.y)
      ..scale(currentScale);

    // Dispose previous animation controller if it exists
    _scrollAnimationController?.dispose();

    // Create new animation controller
    _scrollAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create animation that interpolates between current and target matrix
    final animation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
        .animate(
      CurvedAnimation(
        parent: _scrollAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Listen to animation updates
    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    // Start the animation
    _scrollAnimationController!.forward();
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
    required List<TimelineRow> rows,
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
    const rowHeight =
        75.0; // Default row height (not used for positioning anymore)
    const eventHeight = 45.0; // 60% of default row height
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

    // Timeline height based on actual row heights with extra padding for zoom-out
    final baseTimelineHeight = rows.fold<double>(
      0.0,
      (sum, row) => sum + row.height,
    );

    // Add significant padding to allow for more zoom-out flexibility
    // This ensures users can always zoom out beyond the content bounds
    final timelineHeight =
        baseTimelineHeight * 2.0; // Double the height for zoom-out room

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
      minScale: 0.1, // Allow more zoom-out
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
            height: row.height, // Use actual row height
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
          height: row.height, // Use actual row height
          child: _TimelineRowWidget(row: row, dimensions: dimensions),
        ),
      );
    }

    return widgets;
  }

  double _calculateRowPosition(int index) {
    // Calculate cumulative height for rows above this index
    double position = 0.0;
    for (int i = 0; i < index && i < rows.length; i++) {
      position += rows[i].height;
    }

    // Only animate if we have both a dragged row AND a valid drop target
    if (draggedRowIndex == null ||
        dragTargetIndex == null ||
        dragTargetIndex == -1) {
      return position;
    }

    final draggedIndex = draggedRowIndex!;
    final targetIndex = dragTargetIndex!;

    // Animate rows to make space for the dragged row
    if (draggedIndex < targetIndex) {
      // Dragging down: rows between draggedIndex and targetIndex move up
      if (index > draggedIndex && index <= targetIndex) {
        position -= rows[draggedIndex].height;
      }
    } else if (draggedIndex > targetIndex) {
      // Dragging up: rows between targetIndex and draggedIndex move down
      if (index >= targetIndex && index < draggedIndex) {
        position += rows[draggedIndex].height;
      }
    }

    return position;
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

/// Timeline row widget with hover-based resize handle
class _TimelineRowWidget extends StatefulWidget {
  final TimelineRow row;
  final _TimelineDimensions dimensions;

  const _TimelineRowWidget({required this.row, required this.dimensions});

  @override
  State<_TimelineRowWidget> createState() => _TimelineRowWidgetState();
}

class _TimelineRowWidgetState extends State<_TimelineRowWidget> {
  bool _isHoveringBottomBorder = false;
  bool _isDragging = false;

  void _onDragStarted() {
    setState(() => _isDragging = true);
  }

  void _onDragEnded() {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    // Show handle if hovering OR actively dragging
    final shouldShowHandle = _isHoveringBottomBorder || _isDragging;

    return Container(
      height: widget.row.height,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Stack(
        children: [
          // Vertical grid lines behind events
          _RulerGrid(
            divisions: widget.dimensions.divisions,
            totalWidth: widget.dimensions.timelineWidth,
            height: widget.row.height,
          ),
          // Event boxes with dynamic content based on row height
          ...widget.row.events.map(
            (event) => _EventBox(
              event: event,
              dimensions: widget.dimensions,
              rowHeight: widget.row.height,
            ),
          ),
          // Bottom border hover area for resize handle
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 8, // 8px hover zone at bottom
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHoveringBottomBorder = true),
              onExit: (_) => setState(() => _isHoveringBottomBorder = false),
              child: Container(
                color: Colors.transparent, // Invisible but detects hovers
                child: shouldShowHandle
                    ? _ResizeHandle(
                        rowIndex: widget.row.index,
                        currentHeight: widget.row.height,
                        onDragStarted: _onDragStarted,
                        onDragEnded: _onDragEnded,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Event display component
class _EventBox extends StatefulWidget {
  final Event event;
  final _TimelineDimensions dimensions;
  final double rowHeight;

  const _EventBox({
    required this.event,
    required this.dimensions,
    required this.rowHeight,
  });

  @override
  State<_EventBox> createState() => _EventBoxState();
}

class _EventBoxState extends State<_EventBox> {
  bool _isHovered = false;

  /// Get the display height for this event based on row height
  double _getEventDisplayHeight() {
    // For compact rows (≤75px), use standard event height
    if (widget.rowHeight <= 75) {
      return widget.dimensions.eventHeight;
    }
    // For taller rows, maintain symmetric padding (same as top padding)
    final topPadding =
        (75.0 - widget.dimensions.eventHeight) /
        2; // Same as verticalTop calculation
    final availableHeight =
        widget.rowHeight - (topPadding * 2); // Subtract top and bottom padding
    return availableHeight.clamp(
      widget.dimensions.eventHeight,
      double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
      builder: (context, visibilityState) {
        // Check if this event should be hidden
        if (visibilityState.hiddenIds.contains(widget.event.id)) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<TimelineCubit, TimelineState>(
          builder: (context, state) {
            final color = _getEventColor(widget.event);
            final isGrouped = widget.event.type == EventType.grouped;

            // Check if this event is hovered from external source (like map)
            final isExternallyHovered =
                state.hoveredEvent?.id == widget.event.id;
            final isEffectivelyHovered = _isHovered || isExternallyHovered;

            // Check if this event is selected
            final isSelected = state.selectedEvent?.id == widget.event.id;

            // Calculate positioning
            final leftOffset = _calculateLeftOffset();
            // Position events to look centered at default height, then grow down from there
            final verticalTop =
                (75.0 - widget.dimensions.eventHeight) /
                2; // Centers at default 75px height

            // Handle grouped events specially
            if (isGrouped) {
              return Transform.translate(
                offset: Offset(leftOffset, verticalTop),
                child: _buildHoverableEvent(
                  isEffectivelyHovered: isEffectivelyHovered,
                  isSelected: isSelected,
                  child: _GroupedEventWidget(
                    event: widget.event,
                    dimensions: widget.dimensions,
                    color: color,
                    rowHeight: widget.rowHeight,
                  ),
                ),
              );
            }

            final isPeriodic = widget.event.hasDuration;
            final eventDuration = isPeriodic
                ? widget.event.duration!
                : widget.dimensions.defaultEventDuration;

            final textWidth = _computeEventTextWidth(eventDuration);

            return Transform.translate(
              offset: Offset(leftOffset, verticalTop),
              child: SizedBox(
                width: textWidth,
                height: _getEventDisplayHeight(),
                child: _buildHoverableEvent(
                  isEffectivelyHovered: isEffectivelyHovered,
                  isSelected: isSelected,
                  child: isPeriodic
                      ? _PeriodEventWidget(
                          event: widget.event,
                          color: color,
                          eventDuration: eventDuration,
                          dimensions: widget.dimensions,
                          rowHeight: widget.rowHeight,
                        )
                      : _PointEventWidget(
                          event: widget.event,
                          color: color,
                          dimensions: widget.dimensions,
                          rowHeight: widget.rowHeight,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHoverableEvent({
    required Widget child,
    required bool isEffectivelyHovered,
    required bool isSelected,
  }) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        context.read<TimelineCubit>().setHoveredEvent(widget.event);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        context.read<TimelineCubit>().clearHoveredEvent();
      },
      child: GestureDetector(
        onTap: () {
          // Select the event when clicked
          context.read<TimelineCubit>().selectEvent(widget.event);
          // Mark event as viewed for recently viewed
          context.read<ComparisonBloc>().add(MarkEventAsViewed(widget.event));
          // Show event details panel
          context.read<NavigationBloc>().add(
            ShowEventDetails(widget.event, EventDetailsSource.timeline),
          );
        },
        onLongPress: () {
          _showComparisonContextMenu(context);
        },
        onSecondaryTap: () {
          _showComparisonContextMenu(context);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Add selection overlay when selected - larger border that overlays adjacent events
            if (isSelected)
              Positioned(
                left: -8, // Extend 8px to the left
                right: -8, // Extend 8px to the right
                top: -8, // Extend 8px upward
                bottom: -8, // Extend 8px downward
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurpleAccent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            // Add highlight overlay when hovered (either directly or from map) - only if not selected
            if (isEffectivelyHovered && !isSelected)
              Positioned(
                left:
                    -6, // Extend 6px to the left (slightly smaller than selection)
                right: -6, // Extend 6px to the right
                top: -6, // Extend 6px upward
                bottom: -6, // Extend 6px downward
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurpleAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            child,
            // Action buttons - only show when directly hovered (not from map)
            if (_isHovered) ...[
              // "View on Map" button - only show if event has coordinates
              if (widget.event.hasCoordinates)
                Positioned(
                  right: -8,
                  top: -8,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to event on map
                      context.read<MapCubit>().navigateToEvent(widget.event);
                    },
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.map,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'View on Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // "Add to Compare" button
              Positioned(
                right: widget.event.hasCoordinates ? 120 : -8,
                top: -8,
                child: BlocBuilder<ComparisonBloc, ComparisonState>(
                  builder: (context, comparisonState) {
                    final isInComparison = comparisonState.isEventInComparison(
                      widget.event.id,
                    );
                    final isAtMaxCapacity = comparisonState.isAtMaxCapacity;

                    return GestureDetector(
                      onTap: isInComparison || isAtMaxCapacity
                          ? null
                          : () {
                              context.read<ComparisonBloc>().add(
                                AddEventToComparison(widget.event),
                              );
                            },
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isInComparison
                                ? Colors.green
                                : (isAtMaxCapacity
                                      ? Colors.grey
                                      : Colors.orange),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isInComparison
                                    ? Icons.check
                                    : Icons.compare_arrows,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isInComparison
                                    ? 'Added'
                                    : (isAtMaxCapacity
                                          ? 'Max Reached'
                                          : 'Add to Compare'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showComparisonContextMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem(
          child: BlocBuilder<ComparisonBloc, ComparisonState>(
            builder: (context, state) {
              final isInComparison = state.isEventInComparison(widget.event.id);
              final isAtMaxCapacity = state.isAtMaxCapacity;

              if (isInComparison) {
                return const Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Already in comparison'),
                  ],
                );
              } else if (isAtMaxCapacity) {
                return const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Comparison list is full'),
                  ],
                );
              } else {
                return const Row(
                  children: [
                    Icon(Icons.compare_arrows),
                    SizedBox(width: 8),
                    Text('Add to comparison'),
                  ],
                );
              }
            },
          ),
          onTap: () {
            final comparisonBloc = context.read<ComparisonBloc>();
            final state = comparisonBloc.state;

            if (!state.isEventInComparison(widget.event.id) &&
                !state.isAtMaxCapacity) {
              comparisonBloc.add(AddEventToComparison(widget.event));
            }
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.open_in_new),
              SizedBox(width: 8),
              Text('View comparison overlay'),
            ],
          ),
          onTap: () {
            context.read<ComparisonBloc>().add(
              const ShowComparisonSelectionOverlay(),
            );
          },
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
    return eventColors[event.hashCode % eventColors.length].shade200;
  }

  double _computeEventTextWidth(Duration eventDuration) {
    final maxTextSpan = eventDuration < widget.dimensions.defaultEventDuration
        ? widget.dimensions.defaultEventDuration
        : eventDuration;
    // Use the same calculation method as the grid: hours * pixelsPerHour
    return maxTextSpan.inHours * widget.dimensions.pixelsPerHour;
  }

  double _calculateLeftOffset() {
    final isGrouped = widget.event.type == EventType.grouped;

    // For grouped events, calculate the leftmost position based on all members
    if (isGrouped &&
        widget.event.members != null &&
        widget.event.members!.isNotEmpty) {
      final memberPositions = widget.event.members!.map((member) {
        final memberOffset = member.timestamp.difference(
          widget.dimensions.visibleStart,
        );
        return memberOffset.inHours * widget.dimensions.pixelsPerHour;
      }).toList();

      final minMemberPos = memberPositions.reduce((a, b) => a < b ? a : b);
      final circleRadius = widget.dimensions.memberCircleSize / 2;
      return minMemberPos - circleRadius; // Left edge of first circle
    }

    // For regular events
    final eventOffset = widget.event.effectiveStartTime.difference(
      widget.dimensions.visibleStart,
    );
    // Use the same calculation method as the grid: hours * pixelsPerHour
    final timestampPixelPosition =
        eventOffset.inHours * widget.dimensions.pixelsPerHour;

    // For point events, center the circle on the timestamp
    final isPeriodic = widget.event.hasDuration;
    return isPeriodic
        ? timestampPixelPosition
        : timestampPixelPosition -
              (widget.dimensions.eventHeight / 2); // Center the circle
  }
}

/// Point event widget (circular event)
class _PointEventWidget extends StatelessWidget {
  final Event event;
  final Color color;
  final _TimelineDimensions dimensions;
  final double rowHeight;

  const _PointEventWidget({
    required this.event,
    required this.color,
    required this.dimensions,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    // For compact rows, show traditional layout
    if (rowHeight <= 75) {
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

    // For expanded rows, show vertical layout with image and description
    return ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: circle + title
          Row(
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
          ),
          // Expanded content below (only if enough space)
          if (rowHeight > 130) ...[
            SizedBox(height: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description first
                  Flexible(
                    child: Text(
                      event.displayDescription,
                      style: TextStyle(
                        fontSize: dimensions.fontSize - 1,
                        color: Colors.grey[600],
                      ),
                      maxLines: rowHeight > 170 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Image below description (if row is tall enough)
                  if (rowHeight > 170) ...[
                    SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'volcano_graph_image.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Period event widget (rectangular event with duration)
class _PeriodEventWidget extends StatelessWidget {
  final Event event;
  final Color color;
  final Duration eventDuration;
  final _TimelineDimensions dimensions;
  final double rowHeight;

  const _PeriodEventWidget({
    required this.event,
    required this.color,
    required this.eventDuration,
    required this.dimensions,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = _computeEventFullWidth();

    // For compact rows, show traditional layout
    if (rowHeight <= 75) {
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
              padding: EdgeInsets.symmetric(
                horizontal: dimensions.eventPadding,
              ),
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

    // For expanded rows, show fixed container with expandable content below
    return ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed height container (same as compact)
          Stack(
            children: [
              Container(
                width: fullWidth,
                height: dimensions.eventHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dimensions.eventOpacity),
                  borderRadius: BorderRadius.circular(
                    dimensions.eventBorderRadius,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: dimensions.eventPadding,
                  ),
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
          ),
          // Expanded content below the container (only if enough space)
          if (rowHeight > 130) ...[
            SizedBox(height: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description first
                  Flexible(
                    child: Text(
                      event.displayDescription,
                      style: TextStyle(
                        fontSize: dimensions.fontSize - 1,
                        color: Colors.grey[600],
                      ),
                      maxLines: rowHeight > 170 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Image below description (if row is tall enough)
                  if (rowHeight > 170) ...[
                    SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'volcano_graph_image.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
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
  final double rowHeight;

  const _GroupedEventWidget({
    required this.event,
    required this.dimensions,
    required this.color,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (event.members == null || event.members!.isEmpty) {
      return _PointEventWidget(
        event: event,
        color: color,
        dimensions: dimensions,
        rowHeight: rowHeight,
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
          // Group border line - only span timestamp range
          Positioned(
            left:
                circleRadius, // Offset by circle radius since container starts earlier
            child: _GroupHorizontalLines(
              width: maxMemberPos - minMemberPos, // Only timestamp range
              height: dimensions.eventHeight,
              color: color,
            ),
          ),
          // Member circles - positioned on top of the border
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

/// Group border widget for grouped events
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
    const borderThickness = 2.0;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: borderThickness),
          borderRadius: BorderRadius.circular(2),
          color: color.withValues(alpha: 0.05), // Light background fill
        ),
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
  final double actualTimelineWidth;

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
    required this.actualTimelineWidth,
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

      // Calculate row position after transformation using cumulative heights
      double rowTop = 0.0;
      for (int i = 0; i < index && i < rows.length; i++) {
        rowTop += rows[i].height;
      }
      final transformedY = rowTop * scale + translationY;
      final handleY = transformedY + (rows[index].height * scale - 40) / 2;

      // Check if row is visible on screen
      final isVisible =
          transformedY > -rows[index].height * scale &&
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
                      actualTimelineWidth: actualTimelineWidth,
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

      // Calculate row position after transformation using cumulative heights
      double rowTop = 0.0;
      for (int i = 0; i < index && i < rows.length; i++) {
        rowTop += rows[i].height;
      }
      final transformedY = rowTop * scale + translationY;
      final transformedHeight = rows[index].height * scale;

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
  final double actualTimelineWidth;

  const _DragFeedback({
    required this.row,
    required this.dimensions,
    required this.transformationController,
    required this.actualTimelineWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Get current transformation
    final matrix = transformationController.value;
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();

    // Calculate what part of the timeline is currently visible on screen
    // Use actual timeline width instead of full screen width for accurate calculations
    final timelineWidth = actualTimelineWidth > 0
        ? actualTimelineWidth
        : MediaQuery.of(context).size.width;
    final visibleTimelineStart =
        -translation.x / scale; // Left edge of visible area in timeline coords
    final visibleTimelineWidth =
        timelineWidth / scale; // Width of visible area in timeline coords
    final visibleTimelineEnd = visibleTimelineStart + visibleTimelineWidth;

    // Create a preview showing only the visible portion at current scale
    final previewWidth = timelineWidth * 0.8;
    final previewHeight = row.height * scale; // Scale the height to match zoom

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
                              rowHeight: row.height,
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

/// Resize handle widget for adjusting row height
class _ResizeHandle extends StatefulWidget {
  final int rowIndex;
  final double currentHeight;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _ResizeHandle({
    required this.rowIndex,
    required this.currentHeight,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double? _initialHeight;
  double? _startY;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _initialHeight = widget.currentHeight;
        _startY = details.globalPosition.dy;
        widget.onDragStarted();
      },
      onPanUpdate: (details) {
        if (_initialHeight != null && _startY != null) {
          final deltaY = details.globalPosition.dy - _startY!;
          final unconstrained = _initialHeight! + deltaY;

          // Apply min/max constraints immediately - match cubit constraints exactly
          const minHeight = 75.0; // Must match TimelineCubit.defaultRowHeight
          const maxHeight = 250.0; // Must match cubit maxHeight
          final newHeight = unconstrained.clamp(minHeight, maxHeight);

          // Update global state directly (no more local optimization)
          context.read<TimelineCubit>().updateRowHeight(
            widget.rowIndex,
            newHeight,
          );
        }
      },
      onPanEnd: (details) {
        _initialHeight = null;
        _startY = null;
        widget.onDragEnded();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.3),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Center(child: Container(height: 2, color: Colors.blue)),
        ),
      ),
    );
  }
}
