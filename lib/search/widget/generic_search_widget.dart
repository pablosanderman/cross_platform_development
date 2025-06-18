import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/generic_search_bloc.dart';
import '../bloc/generic_search_event.dart';
import '../bloc/generic_search_state.dart';

class GenericSearchBar<T> extends StatelessWidget {
  final List<T> Function() loadItems;
  final bool Function(T item, String query) filter;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemSelected;
  final Widget? leadingIcon;
  final EdgeInsets padding;

  const GenericSearchBar({
    super.key,
    required this.loadItems,
    required this.filter,
    required this.itemBuilder,
    this.onItemSelected,
    this.leadingIcon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = GenericSearchBloc<T>(loadItems: loadItems, filter: filter);
        bloc.add(SearchInitialized<T>());
        return bloc;
      },
      child: BlocBuilder<GenericSearchBloc<T>, GenericSearchState<T>>(
        builder: (searchbloc, searchState) {

          return SearchAnchor(
            builder: (context, controller) {
              return SearchBar(
                controller: controller,
                padding: WidgetStatePropertyAll(padding),
                onTap: controller.openView,
                onChanged: (value) {
                  controller.openView();
                  searchbloc.read<GenericSearchBloc<T>>().add(SearchQueryChanged<T>(value));
                },
                leading: leadingIcon,
              );
            },
            suggestionsBuilder: (context, controller) async {
              final results = searchState.filteredItems;

              return results.map((item) {
                return ListTile(
                  title: itemBuilder(item),
                  onTap: () {
                    controller.closeView(item.toString());
                    searchbloc.read<GenericSearchBloc<T>>().add(SearchItemSelected<T>(item));
                    onItemSelected?.call(item);
                  },
                );
              }).toList();
            },
          );
        },
      ),
    );
  }
}