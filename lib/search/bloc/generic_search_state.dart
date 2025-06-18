
class GenericSearchState<T> {
  final List<T> filteredItems;
  final T? selectedItem;

  GenericSearchState({
    required this.filteredItems,
    this.selectedItem,
  });

  GenericSearchState<T> copyWith({
    List<T>? filteredItems,
    T? selectedItem,
  }) {
    return GenericSearchState(
      filteredItems: filteredItems ?? this.filteredItems,
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }
}