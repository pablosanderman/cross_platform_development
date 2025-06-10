import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'navigation/navigation.dart';

const borderColor = Color(0xFF805306);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 1,
          child: Column(
            children: [
              const NavBar(),
              Expanded(
                child: BlocBuilder<NavigationBloc, NavigationState>(
                  builder: (context, state) {
                    final bothVisible = state.showTimeline && state.showMap;

                    return Row(
                      children: [
                        if (state.showTimeline)
                          Expanded(
                            flex: bothVisible ? 1 : 2,
                            child: const LeftSide(),
                          ),
                        if (state.showMap)
                          Expanded(
                            flex: bothVisible ? 1 : 2,
                            child: const RightSide(),
                          ),
                      ],
                    );
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



const sidebarColor = Color(0xFFF6A00C);

class LeftSide extends StatelessWidget {
  const LeftSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: sidebarColor,
        child: Column(children: [Expanded(child: Text("TIMELINE"))]),
      ),
    );
  }
}

const backgroundStartColor = Color(0xFFFFD500);

class RightSide extends StatelessWidget {
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: backgroundStartColor,
        child: Column(children: [Text("MAPMAPMAP")]),
      ),
    );
  }
}


