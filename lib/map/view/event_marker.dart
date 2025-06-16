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
    this.isHighlighted = false,
    this.onTap,
    this.onHover,
    this.onHoverExit,
  });

  /// The event to display
  final Event event;

  /// Whether this marker is currently selected
  final bool isSelected;

  /// Whether this marker is highlighted from timeline hover
  final bool isHighlighted;

  /// Callback when marker is tapped
  final VoidCallback? onTap;

  /// Callback when marker is hovered
  final VoidCallback? onHover;

  /// Callback when marker hover exits
  final VoidCallback? onHoverExit;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(),
      onExit: (_) => onHoverExit?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _getMarkerSize(),
          height: _getMarkerSize(),
          decoration: BoxDecoration(
            color: _getMarkerColor(),
            shape: _getMarkerShape(),
            border: Border.all(
              color: _getBorderColor(),
              width: _getBorderWidth(),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isHighlighted ? 0.5 : 0.3,
                ),
                blurRadius: isHighlighted ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: _buildMarkerContent()),
        ),
      ),
    );
  }

  /// Get the size for this marker based on state
  double _getMarkerSize() {
    if (isSelected) return 32;
    if (isHighlighted) return 28;
    return 24;
  }

  /// Get the border color based on state
  Color _getBorderColor() {
    if (isSelected) return Colors.white;
    if (isHighlighted) return Colors.deepPurpleAccent;
    return Colors.black26;
  }

  /// Get the border width based on state
  double _getBorderWidth() {
    if (isSelected) return 3;
    if (isHighlighted) return 2;
    return 1;
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
