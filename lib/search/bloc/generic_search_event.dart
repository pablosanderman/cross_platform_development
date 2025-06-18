abstract class SearchEvent<T> {}

class SearchInitialized<T> extends SearchEvent<T> {}

class SearchQueryChanged<T> extends SearchEvent<T> {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchItemSelected<T> extends SearchEvent<T> {
  final T selectedItem;
  SearchItemSelected(this.selectedItem);
}
