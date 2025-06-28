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
import 'shared/discussion/cubit/discussion_cubit.dart';
import 'shared/utils/platform_utils.dart';
import 'app.dart';
import 'map/map.dart';
import 'comparison/comparison.dart';

void main() {
  Bloc.observer = const AppObserver();

  // Create repositories and services
  final eventsRepository = const EventsRepository();
  final discussionRepository = const DiscussionRepository();
  final recentlyViewedService = RecentlyViewedService();

  // Create NavigationBloc first
  final navigationBloc = NavigationBloc();

  // Create TimelineCubit first (without MapCubit dependency for now)
  final timelineCubit = TimelineCubit(eventsRepository: eventsRepository);

  // Create MapCubit with NavigationBloc and TimelineCubit
  final mapCubit = MapCubit(
    eventsRepository: eventsRepository,
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

  // Create DiscussionCubit
  final discussionCubit = DiscussionCubit(
    discussionRepository: discussionRepository,
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
        BlocProvider.value(value: discussionCubit),
      ],
      child: const MyApp(),
    ),
  );
  
  // Only setup window on desktop platforms
  if (PlatformUtils.isDesktop) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(1200, 800);
      win.minSize = Size(900, 600);
      win.size = initialSize;
      win.title = "Volcano Monitoring Dashboard";
      win.show();
    });
  }
}
