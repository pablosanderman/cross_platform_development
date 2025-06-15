import 'package:cross_platform_development/app_observer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'navigation/navigation.dart';
import 'map/map.dart';
import 'timeline/timeline.dart';
import 'app.dart';

void main() {
  Bloc.observer = const AppObserver();

  // Create NavigationBloc first
  final navigationBloc = NavigationBloc();

  // Create MapCubit with NavigationBloc so it can show map view
  final mapCubit = MapCubit(navigationBloc: navigationBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: navigationBloc),
        BlocProvider.value(value: mapCubit),
        BlocProvider(create: (_) => TimelineCubit(mapCubit: mapCubit)),
      ],
      child: const MyApp(),
    ),
  );
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(750, 500);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}
