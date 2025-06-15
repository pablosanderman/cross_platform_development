import 'package:cross_platform_development/app_observer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'groups/cubit/groups_bloc.dart';
import 'navigation/navigation.dart';
import 'navigation/nav_item/nav_item.dart';
import 'app.dart';

void main() {
  Bloc.observer = const AppObserver();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationBloc(),),
        BlocProvider(create: (_) => NavItemsCubit(),),
        BlocProvider(create: (_) => GroupsBloc(),)
      ],
      child: const MyApp(),
    )
  );
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(900, 500);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}
