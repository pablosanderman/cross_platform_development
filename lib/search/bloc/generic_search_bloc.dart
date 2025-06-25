import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cross_platform_development/search/bloc/generic_search_event.dart';
import 'package:cross_platform_development/search/bloc/generic_search_state.dart';

class GenericSearchBloc<T> extends Bloc<dynamic, GenericSearchState<T>> {
  final List<T> Function() loadItems;
  final bool Function(T, String) filter;

  GenericSearchBloc({required this.loadItems, required this.filter})
    : super(GenericSearchState<T>()) {
    on<SearchItemSelected<T>>((event, emit) {
      emit(state.copyWith(selectedItem: event.selectedItem));
    });

    on<SearchInitialized<T>>((event, emit) async {
      final allItems = loadItems();
      emit(state.copyWith(filteredItems: allItems));
    });
  }
}
