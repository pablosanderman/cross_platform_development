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
      appBar: AppBar(title: const Text('Timeline')),
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Time ruler
              Container(
                height: 40,
                width: double.infinity,
                color: Colors.grey[100],
                child: CustomPaint(painter: TimeRulerPainter(state)),
              ),
              // Timeline rows
              Expanded(
                child: ListView.builder(
                  itemCount: state.rows.length,
                  itemBuilder: (context, index) {
                    final row = state.rows[index];
                    return Container(
                      height: row.height,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Stack(
                        children: row.events.map((event) {
                          return _EventWidget(event: event, state: state);
                        }).toList(),
                      ),
                    );
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

class _EventWidget extends StatelessWidget {
  final Event event;
  final TimelineState state;

  const _EventWidget({required this.event, required this.state});

  @override
  Widget build(BuildContext context) {
    final startOffset = _getEventPosition(event.startTime);
    final width = _getEventWidth();
    final isPoint = event.endTime == null;
    final hasTextToRight = isPoint || width < 60;

    return Positioned(
      left: startOffset,
      top: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event visual
          Container(
            width: isPoint ? 8 : width,
            height: isPoint ? 8 : 44,
            decoration: BoxDecoration(
              color: isPoint ? Colors.blue : Colors.green,
              shape: isPoint ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isPoint ? null : BorderRadius.circular(4),
            ),
            child: !hasTextToRight && !isPoint
                ? Center(
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : null,
          ),
          if (hasTextToRight) ...[
            const SizedBox(width: 8),
            Text(
              event.title,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  double _getEventPosition(DateTime eventTime) {
    // Simple positioning relative to timeline start
    final duration = eventTime.difference(state.visibleStart);
    return duration.inMilliseconds / 1000 / 3600 * 100; // 100 pixels per hour
  }

  double _getEventWidth() {
    if (event.endTime == null) return 8;
    final duration = event.endTime!.difference(event.startTime);
    return duration.inMilliseconds / 1000 / 3600 * 100; // 100 pixels per hour
  }
}

class TimeRulerPainter extends CustomPainter {
  final TimelineState state;

  TimeRulerPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw hour marks
    var current = DateTime(
      state.visibleStart.year,
      state.visibleStart.month,
      state.visibleStart.day,
      state.visibleStart.hour,
    );

    while (current.isBefore(state.visibleEnd)) {
      final offset =
          current.difference(state.visibleStart).inMilliseconds /
          1000 /
          3600 *
          100; // 100 pixels per hour

      if (offset >= 0 && offset <= size.width) {
        // Draw tick
        canvas.drawLine(
          Offset(offset, size.height - 10),
          Offset(offset, size.height),
          paint,
        );

        // Draw hour label
        textPainter.text = TextSpan(
          text: '${current.hour}:00',
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(offset - textPainter.width / 2, 5));
      }

      current = current.add(const Duration(hours: 1));
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter oldDelegate) {
    return oldDelegate.state.visibleStart != state.visibleStart ||
        oldDelegate.state.visibleEnd != state.visibleEnd;
  }
}
