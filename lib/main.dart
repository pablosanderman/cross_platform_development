import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:cross_platform_development/app.dart';
import 'package:cross_platform_development/timeline_observer.dart';

void main() {
  Bloc.observer = const TimelineObserver();
  runApp(const TimelineApp());
}
