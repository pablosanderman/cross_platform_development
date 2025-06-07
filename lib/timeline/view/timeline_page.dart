import 'package:flutter/material.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_page}
/// A [StatelessWidget] which provides a complete timeline solution
/// with theme support. Requires explicit provider injection - no defaults.
/// {@endtemplate}
class TimelinePage extends StatelessWidget {
  final TimelineProvider provider;
  final TimelineTheme? theme;

  /// {@macro timeline_page}
  const TimelinePage({super.key, required this.provider, this.theme});

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? const TimelineTheme();

    return TimelineThemeData(
      theme: effectiveTheme,
      child: TimelineView(provider: provider),
    );
  }
}

/// {@template core_timeline_widget}
/// A pure timeline widget that accepts raw state and controllers.
/// This is the most decoupled option - works with any state management.
/// {@endtemplate}
class CoreTimelineWidget extends StatelessWidget {
  final TimelineState state;
  final VoidCallback onLoadTimeline;
  final ValueChanged<List<Event>>? onUpdateTimeline;
  final VoidCallback? onRelayoutRows;
  final TimelineTheme? theme;

  /// {@macro core_timeline_widget}
  const CoreTimelineWidget({
    super.key,
    required this.state,
    required this.onLoadTimeline,
    this.onUpdateTimeline,
    this.onRelayoutRows,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? const TimelineTheme();

    return TimelineThemeData(
      theme: effectiveTheme,
      child: _CoreTimelineContent(
        state: state,
        onLoadTimeline: onLoadTimeline,
        onUpdateTimeline: onUpdateTimeline,
        onRelayoutRows: onRelayoutRows,
      ),
    );
  }
}

class _CoreTimelineContent extends StatefulWidget {
  final TimelineState state;
  final VoidCallback onLoadTimeline;
  final ValueChanged<List<Event>>? onUpdateTimeline;
  final VoidCallback? onRelayoutRows;

  const _CoreTimelineContent({
    required this.state,
    required this.onLoadTimeline,
    this.onUpdateTimeline,
    this.onRelayoutRows,
  });

  @override
  State<_CoreTimelineContent> createState() => _CoreTimelineContentState();
}

class _CoreTimelineContentState extends State<_CoreTimelineContent> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    widget.onLoadTimeline();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TimelineThemeData.of(context);

    if (widget.state.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleWindow = widget.state.visibleEnd.difference(
      widget.state.visibleStart,
    );
    final divisions = visibleWindow.inHours;
    final timelineWidth = divisions * theme.pixelsPerHour;
    final timelineHeight = widget.state.rows.length * theme.rowHeight;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: theme.rulerHeight,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text('Timeline Ruler'), // Simplified for demo
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: theme.minScale,
              maxScale: theme.maxScale,
              constrained: false,
              child: SizedBox(
                width: timelineWidth,
                height: timelineHeight,
                child: Column(
                  children: widget.state.rows.map((row) {
                    return Container(
                      height: theme.rowHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Text(
                        'Row ${row.index}: ${row.events.length} events',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Factory methods for different timeline configurations
/// Pared down to essential use cases - others can be composed manually
class TimelineFactory {
  /// Creates a default timeline with basic BLoC provider
  static Widget createDefault() {
    return TimelinePage(provider: TimelineCubit());
  }

  /// Creates a timeline with mock data for testing
  static Widget createWithMockData(List<Event> events, {TimelineTheme? theme}) {
    return TimelinePage(
      provider: TimelineCubit.fromMockData(events),
      theme: theme,
    );
  }

  /// Creates a pure widget with manual state management (most decoupled)
  static Widget createCore({
    required TimelineState state,
    required VoidCallback onLoadTimeline,
    ValueChanged<List<Event>>? onUpdateTimeline,
    VoidCallback? onRelayoutRows,
    TimelineTheme? theme,
  }) {
    return CoreTimelineWidget(
      state: state,
      onLoadTimeline: onLoadTimeline,
      onUpdateTimeline: onUpdateTimeline,
      onRelayoutRows: onRelayoutRows,
      theme: theme,
    );
  }

  /// For advanced use cases, compose services directly:
  /// ```dart
  /// TimelinePage(
  ///   provider: TimelineCubit.withCustomServices(...),
  ///   theme: TimelineTheme(...),
  /// )
  /// ```
}
