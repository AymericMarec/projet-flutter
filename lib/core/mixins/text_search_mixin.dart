bool matchesQueryText(String query, Iterable<String?> fields) {
  final q = _normalize(query);
  if (q.isEmpty) return true;

  return fields
      .where((s) => s != null)
      .map((s) => _normalize(s!))
      .any((value) => value.contains(q));
}

Iterable<T> filterByQueryText<T>(
  Iterable<T> items,
  String query,
  Iterable<String?> Function(T item) fields,
) {
  final q = _normalize(query);
  if (q.isEmpty) return items;
  return items.where((item) => matchesQueryText(q, fields(item)));
}

mixin TextSearchMixin {
  bool matchesQuery(String query, Iterable<String?> fields) =>
      matchesQueryText(query, fields);

  Iterable<T> filterByQuery<T>(
    Iterable<T> items,
    String query,
    Iterable<String?> Function(T item) fields,
  ) => filterByQueryText(items, query, fields);
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

