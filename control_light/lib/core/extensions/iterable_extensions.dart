extension IterableMapIndexed<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var i = 0;
    for (final item in this) {
      yield f(i, item);
      i++;
    }
  }
}
