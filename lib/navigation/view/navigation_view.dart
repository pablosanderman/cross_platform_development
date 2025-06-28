import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cross_platform_development/search/search.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../utc_timer/utc_timer.dart';
import '../nav_item/nav_item.dart';
import '../../shared/utils/platform_utils.dart';
import 'mobile_navigation_bar.dart';
import 'dart:io';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Return mobile navigation on mobile platforms
    if (PlatformUtils.isMobile) {
      return const MobileNavigationBar();
    }
    
    // Return desktop navigation on desktop platforms (unchanged)
    return Container(
      color: Color.fromARGB(100, 120, 70, 1),
      child: WindowTitleBarBox(
        child: Row(
          children: [
            BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, navState) {
                return BlocBuilder<NavItemsCubit, NavItemsState>(
                  builder: (context, itemsState) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: Platform.isMacOS ? 60.0 : 8.0,
                        right: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: itemsState.items.reversed.map((item) {
                          return buildNavButton(
                            context,
                            item.label,
                            onPressed: () {
                              if (item.requiresToggle) {
                                if (item.label == 'Timeline') {
                                  context.read<NavigationBloc>().add(
                                    ToggleTimeline(),
                                  );
                                } else if (item.label == 'Map') {
                                  context.read<NavigationBloc>().add(
                                    ToggleMap(),
                                  );
                                }
                              } else {
                                context.read<NavigationBloc>().add(
                                  ChangePage(item.pageIndex),
                                );
                              }
                            },
                            isSelected: item.requiresToggle
                                ? (item.label == 'Timeline' &&
                                          navState.showTimeline &&
                                          navState.currentPageIndex == 0) ||
                                      (item.label == 'Map' &&
                                          navState.showMap &&
                                          navState.currentPageIndex == 0)
                                : navState.currentPageIndex == item.pageIndex,
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),

            Expanded(child: MoveWindow()),

            // Navigation Search Bar Wrapped in Expanded to make it flexible.
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 3.0,
                ),
                child: EventSearchView(),
              ),
            ),

            BlocProvider(
              create: (_) => UtcTimeCubit(),
              child: const UtcTimerView(),
            ),
            const WindowButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildNavButton(
    BuildContext context,
    String label, {
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[300] : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFFF6A00C),
  mouseDown: const Color(0xFF805306),
  iconMouseOver: const Color(0xFF805306),
  iconMouseDown: const Color(0xFFFFD500),
);

final closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
