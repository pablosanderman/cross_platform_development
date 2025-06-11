﻿import 'package:cross_platform_development/navigation/navigation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_development/utc_timer/utc_timer.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationBloc = context.read<NavigationBloc>();

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
                          buildNavButton(navigationBloc, "History", PlaceHolder(),),
                          buildNavButton(navigationBloc, "Notifications", PlaceHolder(),),
                          buildNavButton(navigationBloc, "Group", PlaceHolder(),),
                          buildNavButton(navigationBloc, "Timeline", ToggleTimeline(),),
                          buildNavButton(navigationBloc, "Map", ToggleMap()),

                        ],
                      ),
                    );
                  },
                ),

                Expanded(child: MoveWindow()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                  child: NavigationSearchBar()
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

  TextButton buildNavButton(
    NavigationBloc navigationBloc,
    String title,
    NavigationEvent event,
  ) {
    return TextButton(
      child: Text(title),
      onPressed: () {
        navigationBloc.add(event);
      },
    );
  }
}

class NavigationSearchBar extends StatefulWidget {
  const NavigationSearchBar({super.key});

  @override
  State<NavigationSearchBar> createState() => _NavigationSearchBarState();
}

class _NavigationSearchBarState extends State<NavigationSearchBar> {

  // This is an example list, here we can put a list of all the events from the timeline. Or just further beneath.
  final List<String> allItems = List<String>.generate(
    20,
    (index) => 'item $index',
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: SearchAnchor(
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
              (BuildContext context, SearchController controller) {
                final String input = controller.text;
                final List<String> filteredItems = allItems
                    .where(
                      (item) =>
                          item.toLowerCase().contains(input.toLowerCase()),
                    )
                    .toList();

                return List<ListTile>.generate(filteredItems.length, (
                  int index,
                ) {
                  final String item = filteredItems[index];
                  return ListTile(
                    title: Text(item),
                    onTap: () {
                      controller.closeView(item);
                    },
                  );
                });
              },
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
