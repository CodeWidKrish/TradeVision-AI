sealed class AsyncViewState<T> {
  const AsyncViewState();
}

class ViewLoading<T> extends AsyncViewState<T> {
  const ViewLoading();
}

class ViewData<T> extends AsyncViewState<T> {
  final T data;
  const ViewData(this.data);
}

class ViewError<T> extends AsyncViewState<T> {
  final String message;
  const ViewError(this.message);
}
