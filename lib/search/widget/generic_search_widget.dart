import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/generic_search_bloc.dart';
import '../bloc/generic_search_event.dart';
import '../bloc/generic_search_state.dart';

class GenericSearchBar<T> extends StatefulWidget {
  final List<T> Function() loadItems;
  final bool Function(T item, String query) filter;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) itemTitle;
  final void Function(T item)? onItemSelected;
  final Widget? leadingIcon;
  final EdgeInsets padding;
  final bool fullScreen;

  const GenericSearchBar({
    super.key,
    required this.loadItems,
    required this.filter,
    required this.itemBuilder,
    required this.itemTitle,
    this.onItemSelected,
    this.leadingIcon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
    this.fullScreen = false,
  });

  @override
  State<GenericSearchBar<T>> createState() => _GenericSearchBarState<T>();
}

class _GenericSearchBarState<T> extends State<GenericSearchBar<T>> {
  bool _hasOpenedView = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = GenericSearchBloc<T>(
          loadItems: widget.loadItems,
          filter: widget.filter,
        );
        bloc.add(SearchInitialized<T>());
        return bloc;
      },
      child: BlocBuilder<GenericSearchBloc<T>, GenericSearchState<T>>(
        builder: (searchbloc, searchState) {
          return SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              // If fullScreen and haven't opened yet, automatically open the search view
              if (widget.fullScreen && !_hasOpenedView) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.openView();
                  _hasOpenedView = true;
                });
              }

              return SearchBar(
                controller: controller,
                padding: WidgetStatePropertyAll(widget.padding),
                onTap: controller.openView,
                onChanged: (value) {
                  controller.openView();
                },
                leading: widget.leadingIcon,
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
                  final String input = controller.text;

                  return Future.value(
                    widget
                        .loadItems()
                        .where(
                          (item) => widget.filter(item, input.toLowerCase()),
                        )
                        .map<Widget>(
                          (item) => ListTile(
                            title: widget.itemBuilder(item),
                            onTap: () {
                              controller.closeView(widget.itemTitle(item));
                              searchbloc.read<GenericSearchBloc<T>>().add(
                                SearchItemSelected<T>(item),
                              );
                              widget.onItemSelected?.call(item);
                            },
                          ),
                        )
                        .toList(),
                  );
                },
          );
        },
      ),
    );
  }
}
