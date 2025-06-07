import 'package:flutter/material.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// Timeline theme configuration
class TimelineTheme {
  final double pixelsPerHour;
  final double rowHeight;
  final double rulerHeight;
  final double eventHeight;
  final double eventPadding;
  final double eventBorderRadius;
  final double eventOpacity;
  final double eventSpacing;
  final double fontSize;
  final double rulerFontSize;
  final double minScale;
  final double maxScale;
  final Duration defaultEventDuration;

  // UI colors and styling
  final Color backgroundColor;
  final Color borderColor;
  final Color rulerBackgroundColor;
  final Color textColor;

  const TimelineTheme({
    this.pixelsPerHour = 120.0,
    this.rowHeight = 60.0,
    this.rulerHeight = 40.0,
    this.eventHeight = 32.0,
    this.eventPadding = 8.0,
    this.eventBorderRadius = 4.0,
    this.eventOpacity = 0.8,
    this.eventSpacing = 4.0,
    this.fontSize = 12.0,
    this.rulerFontSize = 11.0,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.defaultEventDuration = const Duration(hours: 3),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE0E0E0),
    this.rulerBackgroundColor = const Color(0xFFEEEEEE),
    this.textColor = const Color(0xFF212121),
  });
}

/// Inherited widget for timeline theme
class TimelineThemeData extends InheritedWidget {
  final TimelineTheme theme;

  const TimelineThemeData({
    super.key,
    required this.theme,
    required super.child,
  });

  static TimelineTheme of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<TimelineThemeData>();
    return inherited?.theme ?? const TimelineTheme();
  }

  @override
  bool updateShouldNotify(TimelineThemeData oldWidget) {
    return theme != oldWidget.theme;
  }
}

/// {@template timeline_view}
/// A [StatelessWidget] which reacts to a [TimelineProvider]
/// and is fully decoupled from any specific state management implementation.
/// {@endtemplate}
class TimelineView extends StatefulWidget {
  /// The timeline provider interface (required - no fallback)
  final TimelineProvider provider;

  /// {@macro timeline_view}
  const TimelineView({super.key, required this.provider});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    widget.provider.loadTimeline();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return StreamBuilder<TimelineState>(
      stream: widget.provider.stream,
      initialData: widget.provider.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.provider.state;
        return _buildTimelineContent(state, theme);
      },
    );
  }

  Widget _buildTimelineContent(TimelineState state, TimelineTheme theme) {
    // Show error if present
    if (state.error != null) {
      return _TimelineErrorView(
        error: state.error!,
        onRetry: widget.provider.loadTimeline,
      );
    }

    // Show loading
    if (state.isLoading || state.rows.isEmpty) {
      return const _TimelineLoadingView();
    }

    // Calculate dimensions
    final visibleWindow = state.visibleEnd.difference(state.visibleStart);
    final divisions = visibleWindow.inHours;
    final timelineWidth = divisions * theme.pixelsPerHour;
    final timelineHeight = state.rows.length * theme.rowHeight;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          _TimelineRuler(
            state: state,
            timelineWidth: timelineWidth,
            divisions: divisions,
            transformationController: _transformationController,
          ),
          Expanded(
            child: _TimelineContent(
              state: state,
              timelineWidth: timelineWidth,
              timelineHeight: timelineHeight,
              visibleWindow: visibleWindow,
              divisions: divisions,
              transformationController: _transformationController,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error display widget
class _TimelineErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _TimelineErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Timeline Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: theme.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Loading display widget
class _TimelineLoadingView extends StatelessWidget {
  const _TimelineLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Timeline ruler component
class _TimelineRuler extends StatelessWidget {
  final TimelineState state;
  final double timelineWidth;
  final int divisions;
  final TransformationController transformationController;

  const _TimelineRuler({
    required this.state,
    required this.timelineWidth,
    required this.divisions,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return Container(
      height: theme.rulerHeight,
      decoration: BoxDecoration(
        color: theme.rulerBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: transformationController,
          builder: (context, child) {
            final matrix = transformationController.value;
            final translation = matrix.getTranslation();
            final scale = matrix.getMaxScaleOnAxis();

            return SizedBox(
              height: theme.rulerHeight,
              child: Stack(
                children: [
                  // Scaled ruler structure
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
                        height: theme.rulerHeight,
                        child: _RulerGrid(
                          divisions: divisions,
                          totalWidth: timelineWidth,
                          height: theme.rulerHeight,
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
                        width: timelineWidth * scale,
                        height: theme.rulerHeight,
                        child: _RulerLabels(
                          state: state,
                          timelineWidth: timelineWidth,
                          scale: scale,
                          divisions: divisions,
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

/// Timeline content with interactive viewer
class _TimelineContent extends StatelessWidget {
  final TimelineState state;
  final double timelineWidth;
  final double timelineHeight;
  final Duration visibleWindow;
  final int divisions;
  final TransformationController transformationController;

  const _TimelineContent({
    required this.state,
    required this.timelineWidth,
    required this.timelineHeight,
    required this.visibleWindow,
    required this.divisions,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return InteractiveViewer(
      transformationController: transformationController,
      minScale: theme.minScale,
      maxScale: theme.maxScale,
      constrained: false,
      child: SizedBox(
        width: timelineWidth,
        height: timelineHeight,
        child: Column(
          children: state.rows
              .map(
                (row) => _TimelineRowWidget(
                  row: row,
                  state: state,
                  timelineWidth: timelineWidth,
                  visibleWindow: visibleWindow,
                  divisions: divisions,
                ),
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
    final theme = TimelineThemeData.of(context);
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
                    ? BorderSide(color: theme.borderColor)
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
  final TimelineState state;
  final double timelineWidth;
  final double scale;
  final int divisions;

  const _RulerLabels({
    required this.state,
    required this.timelineWidth,
    required this.scale,
    required this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);
    final segmentWidth = timelineWidth * scale / divisions;

    return Row(
      children: List.generate(divisions, (index) {
        final segmentStart = state.visibleStart.add(Duration(hours: index));
        final label =
            '${segmentStart.day}/${segmentStart.month} ${segmentStart.hour.toString().padLeft(2, '0')}:00';

        return SizedBox(
          width: segmentWidth,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: theme.rulerFontSize,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
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
  final TimelineState state;
  final double timelineWidth;
  final Duration visibleWindow;
  final int divisions;

  const _TimelineRowWidget({
    required this.row,
    required this.state,
    required this.timelineWidth,
    required this.visibleWindow,
    required this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    return Container(
      height: theme.rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Stack(
        children: [
          // Vertical grid lines behind events
          _RulerGrid(
            divisions: divisions,
            totalWidth: timelineWidth,
            height: theme.rowHeight,
          ),
          // Event boxes
          ...row.events.map(
            (event) => _EventBox(
              event: event,
              state: state,
              timelineWidth: timelineWidth,
              visibleWindow: visibleWindow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Event display component
class _EventBox extends StatelessWidget {
  final Event event;
  final TimelineState state;
  final double timelineWidth;
  final Duration visibleWindow;

  const _EventBox({
    required this.event,
    required this.state,
    required this.timelineWidth,
    required this.visibleWindow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);
    final color = _getEventColor(event);
    final isGrouped = event.type == EventType.grouped;

    // Handle grouped events specially
    if (isGrouped) {
      return _buildGroupedEvent(color, theme);
    }

    final isPeriodic = event.hasDuration;
    final eventDuration = isPeriodic
        ? event.duration!
        : theme.defaultEventDuration;

    final textWidth = _computeEventTextWidth(eventDuration, theme);

    return _wrapEventPosition(
      child: SizedBox(
        width: textWidth,
        height: theme.eventHeight,
        child: isPeriodic
            ? _buildPeriodEvent(color, eventDuration, theme)
            : _buildPointEvent(color, theme),
      ),
    );
  }

  Widget _buildGroupedEvent(Color color, TimelineTheme theme) {
    if (event.members == null || event.members!.isEmpty) {
      return _buildPointEvent(color, theme);
    }

    final members = event.members!;
    final memberPositions = members.map((member) {
      final memberOffset = member.timestamp.difference(state.visibleStart);
      final positionRatio =
          memberOffset.inMilliseconds / visibleWindow.inMilliseconds;
      return positionRatio * timelineWidth;
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
      top: (theme.rowHeight - theme.eventHeight) / 2,
      child: SizedBox(
        width: totalWidth,
        height: theme.eventHeight,
        child: Stack(
          children: [
            // Group border
            Container(
              width: borderWidth,
              height: theme.eventHeight,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
                color: color.withValues(alpha: 0.1),
              ),
            ),
            // Member circles
            ...members.asMap().entries.map((entry) {
              final index = entry.key;
              final absolutePosition = memberPositions[index];
              final relativePosition = absolutePosition - borderLeft;

              return Positioned(
                left: relativePosition,
                top: (theme.eventHeight - 12) / 2,
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
            // Title
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
                    fontSize: theme.fontSize,
                    color: theme.textColor,
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

  Widget _buildPointEvent(Color color, TimelineTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: theme.eventHeight,
          height: theme.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: theme.eventOpacity),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: theme.eventSpacing),
        Expanded(
          child: Text(
            event.title,
            style: TextStyle(fontSize: theme.fontSize, color: theme.textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodEvent(
    Color color,
    Duration eventDuration,
    TimelineTheme theme,
  ) {
    final fullWidth = _computeEventFullWidth(eventDuration);

    return Stack(
      children: [
        Container(
          width: fullWidth,
          height: theme.eventHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: theme.eventOpacity),
            borderRadius: BorderRadius.circular(theme.eventBorderRadius),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.eventPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: theme.fontSize,
                  color: theme.textColor,
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

  double _computeEventTextWidth(Duration eventDuration, TimelineTheme theme) {
    final maxTextSpan = eventDuration < theme.defaultEventDuration
        ? theme.defaultEventDuration
        : eventDuration;
    final ratio = maxTextSpan.inMilliseconds / visibleWindow.inMilliseconds;
    return ratio * timelineWidth;
  }

  double _computeEventFullWidth(Duration eventDuration) {
    final ratio = eventDuration.inMilliseconds / visibleWindow.inMilliseconds;
    return ratio * timelineWidth;
  }

  Widget _wrapEventPosition({required Widget child}) {
    return Builder(
      builder: (context) {
        final theme = TimelineThemeData.of(context);
        final eventOffset = event.effectiveStartTime.difference(
          state.visibleStart,
        );
        final positionRatio =
            eventOffset.inMilliseconds / visibleWindow.inMilliseconds;
        final leftOffset = positionRatio * timelineWidth;
        final verticalCenter = (theme.rowHeight - theme.eventHeight) / 2;

        return Positioned(left: leftOffset, top: verticalCenter, child: child);
      },
    );
  }
}
