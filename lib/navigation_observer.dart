import 'package:bloc/bloc.dart';

class NavigationObserver extends BlocObserver {
  const NavigationObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }
}