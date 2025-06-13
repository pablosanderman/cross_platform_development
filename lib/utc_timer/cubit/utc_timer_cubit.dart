import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class UtcTimeCubit extends Cubit<DateTime> {
  Timer? _timer;

  UtcTimeCubit() : super(DateTime.now().toUtc()) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      emit(DateTime.now().toUtc());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks.
    return super.close();
  }
}
