import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cross_platform_development/utc_timer/utc_timer.dart';
import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:intl/intl.dart';
import 'package:cross_platform_development/comparison/comparison.dart';

/// Mobile navigation bar matching the Figma design
/// Layout: [UTC Clock|Home] [VS Badge] [Groups|Bell|Search]
class MobileNavigationBar extends StatefulWidget {
  const MobileNavigationBar({super.key});

  @override
  State<MobileNavigationBar> createState() => _MobileNavigationBarState();
}

class _MobileNavigationBarState extends State<MobileNavigationBar> {
  bool _showSearchOverlay = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color.fromARGB(255, 40, 40, 40), // Dark background
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                  // Left: UTC Clock only
                  BlocProvider(
                    create: (_) => UtcTimeCubit(),
                    child: const UtcTimerView(),
                  ),

                  // Right: All buttons aligned to the right
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _NavIconButton(
                          icon: Icons.home,
                          onTap: () {
                            // Navigate to main timeline/map page
                            context.read<NavigationBloc>().add(ChangePage(0));
                            context.read<NavigationBloc>().add(ShowTimeline());
                            context.read<NavigationBloc>().add(ShowMap());
                          },
                        ),
                        const SizedBox(width: 4),
                        _VSButton(
                          onTap: () {
                            // Show comparison selection overlay
                            context.read<ComparisonBloc>().add(
                              const ShowComparisonSelectionOverlay(),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _NavIconButton(
                          icon: Icons.group,
                          onTap: () {
                            // Navigate to groups page
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
                            setState(() {
                              _showSearchOverlay = !_showSearchOverlay;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),

              // Search overlay
              if (_showSearchOverlay)
                Positioned(
                  top: 56, // Below the navigation bar
                  left: 0,
                  right: 0,
                  child: _SearchOverlay(
                    onClose: () {
                      setState(() {
                        _showSearchOverlay = false;
                      });
                    },
                    onEventSelected: () {
                      // Close search when an event is selected
                      setState(() {
                        _showSearchOverlay = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation icon button with touch-friendly sizing
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

/// VS button with text instead of icon, same sizing as other nav buttons
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
        child: SizedBox(
          width: 40,
          height: 40,
          child: const Center(
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

/// Search overlay that appears below the navigation bar
class _SearchOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onEventSelected;

  const _SearchOverlay({required this.onClose, required this.onEventSelected});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Container(
        height: 200,
        color: const Color.fromARGB(255, 50, 50, 50),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Close button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
              ],
            ),
            // Search content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _MobileEventSearchView(onEventSelected: onEventSelected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile-specific event search that handles selection callbacks
class _MobileEventSearchView extends StatelessWidget {
  final VoidCallback onEventSelected;

  const _MobileEventSearchView({required this.onEventSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      builder: (context, timelineState) {
        if (timelineState.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white),
                ),
                onChanged: (query) {
                  // Filter events based on query
                  // This is a simplified version - you might want to use a more sophisticated search
                },
              ),
            ),
            // Search results
            Expanded(
              child: ListView.builder(
                itemCount: timelineState.events.length > 5
                    ? 5
                    : timelineState.events.length,
                itemBuilder: (context, index) {
                  final event = timelineState.events[index];
                  final start = event.startTime != null
                      ? DateFormat('HH:mm:ss').format(event.startTime!)
                      : "No Start";
                  return ListTile(
                    title: Text(
                      event.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "Time: $start",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      // Navigate to timeline and select event
                      context.read<NavigationBloc>().add(ChangePage(0));
                      context.read<NavigationBloc>().add(ShowTimeline());
                      context.read<TimelineCubit>().scrollToEvent(event);
                      context.read<TimelineCubit>().selectEvent(event);
                      // Notify parent to close search
                      onEventSelected();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
