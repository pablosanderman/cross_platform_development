import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/utc_timer/utc_timer.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:cross_platform_development/comparison/comparison.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:cross_platform_development/search/search.dart';

/// Mobile navigation bar with direct showSearch() navigation
class MobileNavigationBar extends StatelessWidget {
  const MobileNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color.fromARGB(255, 40, 40, 40),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Left: UTC Clock
              BlocProvider(
                create: (_) => UtcTimeCubit(),
                child: const UtcTimerView(),
              ),

              // Right: Navigation buttons
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _NavIconButton(
                      icon: Icons.home,
                      onTap: () {
                        context.read<NavigationBloc>().add(ChangePage(0));
                        context.read<NavigationBloc>().add(ShowTimeline());
                        context.read<NavigationBloc>().add(ShowMap());
                      },
                    ),
                    const SizedBox(width: 4),
                    _VSButton(
                      onTap: () {
                        context.read<ComparisonBloc>().add(
                          const ShowComparisonSelectionOverlay(),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    _NavIconButton(
                      icon: Icons.group,
                      onTap: () {
                        context.read<NavigationBloc>().add(ChangePage(2));
                      },
                    ),
                    const SizedBox(width: 4),
                    _NavIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () {
                        // TODO: Show notifications
                      },
                    ),
                    const SizedBox(width: 4),
                    _NavIconButton(
                      icon: Icons.search,
                      onTap: () {
                        // Use showSearch() for immediate full-screen search
                        final timelineState = context
                            .read<TimelineCubit>()
                            .state;
                        showSearch(
                          context: context,
                          delegate: EventSearchDelegate(
                            events: timelineState.events,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation icon button
class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// VS button
class _VSButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VSButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
