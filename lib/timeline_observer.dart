import 'package:bloc/bloc.dart';

/// {@template counter_observer}
/// [BlocObserver] for the counter application which
/// observes all state changes.
/// {@endtemplate}
class TimelineObserver extends BlocObserver {
  /// {@macro counter_observer}
  const TimelineObserver();

  // @override
  // void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
  //   super.onChange(bloc, change);
  //   // ignore: avoid_print
  //   print('${bloc.runtimeType} $change');
  // }
}
