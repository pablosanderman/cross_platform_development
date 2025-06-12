import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cross_platform_development/timeline/models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_development/utc_timer/utc_timer.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:intl/intl.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Color.fromARGB(100, 120, 70, 1),
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [
                BlocBuilder<NavigationBloc, NavigationState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // building a navButton like this is a bit cleaner and easier to alter the button placements
                          buildNavButton(
                            context,
                            "History",
                            onPressed: () => PlaceHolder(),
                          ),
                          buildNavButton(
                            context,
                            "Notifications",
                            onPressed: () => PlaceHolder(),
                          ),
                          buildNavButton(
                            context,
                            "Group",
                            onPressed: () =>
                                context.read<NavigationBloc>().add(ChangePage(1)),
                            isSelected:
                              state.currentPageIndex == 1,
                          ),
                          buildNavButton(
                            context,
                            "Timeline",
                            onPressed: () => context.read<NavigationBloc>().add(
                              ToggleTimeline(),
                            ),
                            isSelected:
                                state.showTimeline &&
                                state.currentPageIndex == 0,
                          ),
                          buildNavButton(
                            context,
                            "Map",
                            onPressed: () =>
                                context.read<NavigationBloc>().add(ToggleMap()),
                            isSelected:
                                state.showMap && state.currentPageIndex == 0,
                          ),
                        ],
                      ),
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
                    child: NavigationSearchBar(),
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
        ],
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

class NavigationSearchBar extends StatefulWidget {
  const NavigationSearchBar({super.key});

  @override
  State<NavigationSearchBar> createState() => _NavigationSearchBarState();
}

class _NavigationSearchBarState extends State<NavigationSearchBar> {

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 12.0),
          ),
          onTap: () {
            controller.openView();
          },
          onChanged: (_) {
            controller.openView();
          },
          leading: const Icon(Icons.search),
        );
      },
      suggestionsBuilder:
          (BuildContext context, SearchController controller) async {
            final String input = controller.text;
            final List<Event> events = await TimelineCubit().loadEvents();
            final List<Event> filteredItems = events
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(input.toLowerCase()),
                )
                .toList();

            return List<ListTile>.generate(filteredItems.length, (int index) {
              final Event item = filteredItems[index];
              final startTime = item.startTime != null
                  ? DateFormat('HH:mm:ss').format(item.startTime as DateTime)
                  : "No StartTime";

              final endTime = item.endTime != null
                  ? DateFormat('HH:mm:ss').format(item.endTime as DateTime)
                  : "No EndTime";

              return ListTile(
                title: Text("${item.title}   Date: $startTime --- $endTime"),
                onTap: () {
                  controller.closeView(item.title);
                },
              );
            });
          },
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
