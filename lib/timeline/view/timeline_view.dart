import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/timeline/timeline.dart';

/// {@template timeline_view}
/// A [StatelessWidget] which reacts to the provided
/// [TimelineCubit] state and notifies it in response to user input.
/// {@endtemplate}
class TimelineView extends StatelessWidget {
  /// {@macro timeline_view}
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    context.read<TimelineCubit>().loadTimeline();
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline Rows')),
      body: BlocBuilder<TimelineCubit, TimelineState>(
        builder: (context, state) {
          if (state.rows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: state.rows.length,
            itemBuilder: (context, index) {
              final row = state.rows[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${row.index} (${row.events.length} events)',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...row.events.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                event.endTime == null
                                    ? Icons.circle
                                    : Icons.rectangle,
                                size: 12,
                                color: event.endTime == null
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(event.title)),
                              Text(
                                event.endTime == null
                                    ? 'Point'
                                    : '${event.endTime!.difference(event.startTime).inMinutes}min',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
