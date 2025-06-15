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
    this.onTap,
  });

  /// The events clustered at this location
  final List<Event> events;

  /// Whether any event in this cluster is currently selected
  final bool isSelected;

  /// Callback when cluster is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSelected ? 36 : 30,
        height: isSelected ? 36 : 30,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
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
        child: Center(
          child: Text(
            events.length.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
