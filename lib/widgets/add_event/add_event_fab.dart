import 'package:flutter/material.dart';

/// {@template add_event_fab}
/// A floating action button that triggers the add event overlay.
/// Matches the design of EventVisibilityFab.
/// {@endtemplate}
class AddEventFab extends StatelessWidget {
  /// Callback when the FAB is pressed
  final VoidCallback onPressed;

  /// {@macro add_event_fab}
  const AddEventFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.grey.shade700,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}