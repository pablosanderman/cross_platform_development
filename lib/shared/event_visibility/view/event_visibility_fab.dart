import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/event_visibility_cubit.dart';

/// {@template event_visibility_fab}
/// A floating action button that toggles the event visibility panel.
/// {@endtemplate}
class EventVisibilityFab extends StatelessWidget {
  /// {@macro event_visibility_fab}
  const EventVisibilityFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventVisibilityCubit, EventVisibilityState>(
      builder: (context, state) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.panelOpen ? Colors.blue : Colors.white,
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
              onTap: () {
                context.read<EventVisibilityCubit>().togglePanel();
              },
              child: Center(
                child: Icon(
                  Icons.visibility,
                  color: state.panelOpen ? Colors.white : Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}