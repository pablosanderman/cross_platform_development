import 'package:cross_platform_development/navigation_observer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'navigation/navigation.dart';
import 'app.dart';

void main() {
  Bloc.observer = const NavigationObserver();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NavigationBloc(),
        ),
      ],
      child: const MyApp(),
    )
  );
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1080, 450);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}
