abstract class SearchEvent<T> {}

class SearchInitialized<T> extends SearchEvent<T> {}

class SearchItemSelected<T> extends SearchEvent<T> {
  final T selectedItem;
  SearchItemSelected(this.selectedItem);
}
