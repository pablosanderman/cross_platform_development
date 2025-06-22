
class GenericSearchState<T> {
  final T? selectedItem;

  GenericSearchState({
    this.selectedItem,
  });

  GenericSearchState<T> copyWith({
    List<T>? filteredItems,
    T? selectedItem,
  }) {
    return GenericSearchState(
      selectedItem: selectedItem ?? this.selectedItem,
    );
  }
}