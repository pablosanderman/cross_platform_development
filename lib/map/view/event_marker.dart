import 'package:flutter/material.dart';
import 'package:cross_platform_development/shared/shared.dart';

/// {@template event_marker}
/// A marker widget for displaying events on the map.
/// Shows different colors and styles based on event type.
/// {@endtemplate}
class EventMarker extends StatelessWidget {
  /// {@macro event_marker}
  const EventMarker({
    super.key,
    required this.event,
    this.isSelected = false,
    this.onTap,
  });

  /// The event to display
  final Event event;

  /// Whether this marker is currently selected
  final bool isSelected;

  /// Callback when marker is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSelected ? 32 : 24,
        height: isSelected ? 32 : 24,
        decoration: BoxDecoration(
          color: _getMarkerColor(),
          shape: _getMarkerShape(),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black26,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: _buildMarkerContent()),
      ),
    );
  }

  /// Get the color for this event type
  Color _getMarkerColor() {
    switch (event.type) {
      case EventType.point:
        return Colors.red;
      case EventType.period:
        return Colors.blue;
      case EventType.grouped:
        return Colors.orange;
    }
  }

  /// Get the shape for this event type
  BoxShape _getMarkerShape() {
    switch (event.type) {
      case EventType.point:
        return BoxShape.circle;
      case EventType.period:
        return BoxShape.rectangle;
      case EventType.grouped:
        return BoxShape.circle;
    }
  }

  /// Build the content inside the marker
  Widget _buildMarkerContent() {
    switch (event.type) {
      case EventType.point:
        // Simple circle for point events
        return const SizedBox.shrink();
      case EventType.period:
        // Rectangle for period events
        return const SizedBox.shrink();
      case EventType.grouped:
        // Show number of grouped events
        final memberCount = event.members?.length ?? 0;
        return Text(
          memberCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}
