import 'package:flutter/material.dart';
import 'package:cross_platform_development/shared/shared.dart';

/// {@template cluster_marker}
/// A marker widget for displaying multiple events clustered at the same location.
/// Shows a red circle with white text indicating the number of events.
/// {@endtemplate}
class ClusterMarker extends StatelessWidget {
  /// {@macro cluster_marker}
  const ClusterMarker({
    super.key,
    required this.events,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onHover,
    this.onHoverExit,
  });

  /// The events clustered at this location
  final List<Event> events;

  /// Whether any event in this cluster is currently selected
  final bool isSelected;

  /// Whether any event in this cluster is highlighted from timeline hover
  final bool isHighlighted;

  /// Callback when cluster is tapped
  final VoidCallback? onTap;

  /// Callback when cluster is hovered
  final VoidCallback? onHover;

  /// Callback when cluster hover exits
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
          width: _getClusterSize(),
          height: _getClusterSize(),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
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
          child: Center(
            child: Text(
              events.length.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: _getFontSize(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get the size for this cluster based on state
  double _getClusterSize() {
    if (isSelected) return 36;
    if (isHighlighted) return 34;
    return 30;
  }

  /// Get the border color based on state
  Color _getBorderColor() {
    if (isSelected) return Colors.white;
    if (isHighlighted) return Colors.yellow;
    return Colors.black26;
  }

  /// Get the border width based on state
  double _getBorderWidth() {
    if (isSelected) return 3;
    if (isHighlighted) return 2;
    return 1;
  }

  /// Get the font size based on state
  double _getFontSize() {
    if (isSelected) return 14;
    if (isHighlighted) return 13;
    return 12;
  }
}
