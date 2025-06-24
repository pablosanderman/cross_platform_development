import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/shared/models/event.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:intl/intl.dart';

/// {@template event_details_panel}
/// A comprehensive panel that displays detailed information about a volcanic event.
/// Includes header, content, metadata, and action sections.
/// {@endtemplate}
class EventDetailsPanel extends StatelessWidget {
  /// {@macro event_details_panel}
  const EventDetailsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        final event = navState.selectedEventForDetails;
        final source = navState.detailsSource;

        if (event == null || source == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, event, source),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVisualSection(event),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(event),
                      const SizedBox(height: 24),
                      _buildKeyInformationSection(event),
                      const SizedBox(height: 24),
                      _buildLocationSection(event),
                      const SizedBox(height: 24),
                      _buildMetadataSection(event),
                      const SizedBox(height: 24),
                      _buildActionSection(context, event, source),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Event event,
    EventDetailsSource source,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Event type badge
          _buildEventTypeBadge(event.type),
          const SizedBox(width: 12),

          // Event title and time
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildEventTimeDisplay(event),
              ],
            ),
          ),

          const SizedBox(width: 12),
          // Close button on the right
          IconButton(
            onPressed: () {
              context.read<NavigationBloc>().add(CloseEventDetails());
            },
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeBadge(EventType type) {
    Color badgeColor;
    String badgeText;

    switch (type) {
      case EventType.point:
        badgeColor = Colors.blue;
        badgeText = 'POINT';
        break;
      case EventType.period:
        badgeColor = Colors.green;
        badgeText = 'PERIOD';
        break;
      case EventType.grouped:
        badgeColor = Colors.orange;
        badgeText = 'GROUPED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildVisualSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Visualization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            event.displayImageUrl,
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visualization not available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event.displayDescription,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInformationSection(Event event) {
    final keyInfo = _extractKeyInformation(event);

    if (keyInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...keyInfo.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(Event event) {
    if (!event.hasCoordinates) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.properties?['location'] ?? 'Location not specified',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${event.latitude!.toStringAsFixed(4)}, '
                    'Lon: ${event.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetadataCard('Event Properties', event.properties),
        if (event.aggregateData != null) ...[
          const SizedBox(height: 12),
          _buildMetadataCard('Aggregate Data', event.aggregateData),
        ],
        if (event.members != null && event.members!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildGroupMembersCard(event.members!),
        ],
      ],
    );
  }

  Widget _buildMetadataCard(String title, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMembersCard(List<GroupMember> members) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Members (${members.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...members
              .take(5)
              .map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(member.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.data.entries
                              .take(2)
                              .map((e) => '${e.key}: ${e.value}')
                              .join(', '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (members.length > 5) ...[
            const SizedBox(height: 4),
            Text(
              '+ ${members.length - 5} more members',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    Event event,
    EventDetailsSource source,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildActionButton(
              context,
              icon: Icons.compare_arrows,
              label: 'Add to Compare',
              onPressed: () {
                // TODO: Implement compare functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compare functionality coming soon'),
                  ),
                );
              },
            ),
            if (source == EventDetailsSource.map) ...[
              _buildActionButton(
                context,
                icon: Icons.timeline,
                label: 'View on Timeline',
                onPressed: () {
                  context.read<NavigationBloc>().add(
                    SwitchEventDetailsView(EventDetailsSource.timeline),
                  );
                },
              ),
            ],
            if (source == EventDetailsSource.timeline) ...[
              _buildActionButton(
                context,
                icon: Icons.map,
                label: 'View on Map',
                onPressed: () {
                  context.read<NavigationBloc>().add(
                    SwitchEventDetailsView(EventDetailsSource.map),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.blue.shade200),
        ),
      ),
    );
  }

  Widget _buildEventTimeDisplay(Event event) {
    switch (event.type) {
      case EventType.point:
        return Text(
          _formatEventTime(event),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        );
      case EventType.period:
        return _buildMiniTimeline(event);
      case EventType.grouped:
        return Text(
          _formatEventTime(event),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        );
    }
  }

  Widget _buildMiniTimeline(Event event) {
    final startTime = event.effectiveStartTime;
    final endTime = event.effectiveEndTime;

    final formatter = DateFormat('MMM dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Horizontal timeline: start date - bar - end date
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start date
            Text(
              formatter.format(startTime),
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),

            const SizedBox(width: 8),

            // Timeline bar
            Container(width: 40, height: 2, color: Colors.grey.shade600),

            const SizedBox(width: 8),

            // End date
            Text(
              endTime != null ? formatter.format(endTime) : 'Ongoing',
              style: TextStyle(
                fontSize: 12,
                color: endTime != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Duration underneath
        Text(
          _formatDuration(event.duration),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Ongoing';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatEventTime(Event event) {
    final formatter = DateFormat('MMM dd, yyyy HH:mm');

    switch (event.type) {
      case EventType.point:
        return formatter.format(event.effectiveStartTime);
      case EventType.period:
        final start = formatter.format(event.effectiveStartTime);
        final end = event.effectiveEndTime != null
            ? formatter.format(event.effectiveEndTime!)
            : 'Ongoing';
        return '$start - $end';
      case EventType.grouped:
        final start = formatter.format(event.effectiveStartTime);
        final end = event.effectiveEndTime != null
            ? formatter.format(event.effectiveEndTime!)
            : 'Ongoing';
        return '$start - $end (${event.members?.length ?? 0} events)';
    }
  }

  Map<String, String> _extractKeyInformation(Event event) {
    final info = <String, String>{};
    final properties = event.properties;

    if (properties == null) return info;

    // Add event-specific key information based on properties
    if (properties.containsKey('magnitude')) {
      info['Magnitude'] = 'M ${properties['magnitude']}';
    }

    if (properties.containsKey('depthKm')) {
      info['Depth'] = '${properties['depthKm']} km';
    }

    if (properties.containsKey('vei')) {
      info['VEI'] = '${properties['vei']}';
    }

    if (properties.containsKey('alertLevel')) {
      info['Alert Level'] = properties['alertLevel'].toString().toUpperCase();
    }

    if (properties.containsKey('temperature')) {
      info['Temperature'] = '${properties['temperature']}°C';
    }

    if (properties.containsKey('so2FluxTonsPerDay')) {
      info['SO₂ Flux'] = '${properties['so2FluxTonsPerDay']} tons/day';
    }

    if (properties.containsKey('maxDisplacementCm')) {
      info['Max Displacement'] = '${properties['maxDisplacementCm']} cm';
    }

    if (properties.containsKey('ashHeightKm')) {
      info['Ash Height'] = '${properties['ashHeightKm']} km';
    }

    if (properties.containsKey('region')) {
      info['Region'] = properties['region'].toString();
    }

    return info;
  }
}
