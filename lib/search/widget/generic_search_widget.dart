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
  final String Function(T item) itemTitle;
  final void Function(T item)? onItemSelected;
  final Widget? leadingIcon;
  final EdgeInsets padding;

  const GenericSearchBar({
    super.key,
    required this.loadItems,
    required this.filter,
    required this.itemBuilder,
    required this.itemTitle,
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
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                padding: WidgetStatePropertyAll(padding),
                onTap: controller.openView,
                onChanged: (value) {
                  controller.openView();
                },
                leading: leadingIcon,
              );
            },
            suggestionsBuilder: (
                BuildContext context, SearchController controller) async {
              final String input = controller.text;
              final filteredItems = this.loadItems()
                  .where((item) => filter(item, input)).toList();

              return filteredItems.map((item) {
                return ListTile(
                  title: itemBuilder(item),
                  onTap: () {
                    controller.closeView(itemTitle(item));
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