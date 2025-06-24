import 'package:cross_platform_development/app_observer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cross_platform_development/timeline/timeline.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'groups/bloc/groups_bloc.dart';
import 'groups/groups.dart';
import 'navigation/navigation.dart';
import 'navigation/nav_item/nav_item.dart';
import 'shared/shared.dart';
import 'app.dart';
import 'map/map.dart';
import 'comparison/comparison.dart';
import 'shared/repositories/repositories.dart';

void main() {
  Bloc.observer = const AppObserver();

  // Create repositories and services
  final eventsRepository = const EventsRepository();
  final recentlyViewedService = RecentlyViewedService();

  // Create NavigationBloc first
  final navigationBloc = NavigationBloc();

  // Create TimelineCubit first (without MapCubit dependency for now)
  final timelineCubit = TimelineCubit();

  // Create MapCubit with NavigationBloc and TimelineCubit
  final mapCubit = MapCubit(
    navigationBloc: navigationBloc,
    timelineCubit: timelineCubit,
  );

  // Now set the MapCubit reference in TimelineCubit
  timelineCubit.setMapCubit(mapCubit);

  // Create ComparisonBloc
  final comparisonBloc = ComparisonBloc(
    eventsRepository: eventsRepository,
    recentlyViewedService: recentlyViewedService,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: navigationBloc),
        BlocProvider.value(value: mapCubit),
        BlocProvider.value(value: timelineCubit),
        BlocProvider(create: (_) => NavItemsCubit()),
        BlocProvider(create: (_) => GroupsBloc()),
        BlocProvider(create: (_) => EventVisibilityCubit()),
        BlocProvider.value(value: comparisonBloc),
      ],
      child: const MyApp(),
    ),
  );
  doWhenWindowReady(() {
    final win = appWindow;
    win.title = "Volcano Monitoring Dashboard";
    win.show();
  });
}
