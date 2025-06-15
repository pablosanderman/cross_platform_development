import 'package:cross_platform_development/navigation/nav_item/nav_item.dart';
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
              const NavigationView(),
               BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, navState) {
                  // Hacky way of doing this, please don't kill me :).
                  final currentIndex = navState.currentPageIndex == 1
                      ? navState.currentPageIndex - 1
                      : navState.currentPageIndex;

                  return BlocBuilder<NavItemsCubit, NavItemsState>(
                      builder: (context, itemsState) {
                        return itemsState.items[currentIndex].page;
                      }
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}