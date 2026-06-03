import '../entities/task.dart';

extension TaskIterableUtils on Iterable<Task> {
  Iterable<Task> filterByStatus(TaskStatus status) =>
      where((t) => t.status == status);

  Iterable<Task> filterByStatuses(Set<TaskStatus> statuses) =>
      where((t) => statuses.contains(t.status));

  List<Task> sortedByPriority({bool descending = true}) {
    final list = toList(growable: false);
    final sorted = List<Task>.of(list);
    sorted.sort(
      (a, b) => descending
          ? b.priority.index - a.priority.index
          : a.priority.index - b.priority.index,
    );
    return sorted;
  }

  Iterable<Task> withDueDate() => where((t) => t.dueDate != null);

  Iterable<Task> dueOnDay(DateTime day, {bool includeNoDueDate = false}) {
    final start = _startOfDay(day);
    final end = start.add(const Duration(days: 1));
    return where((t) {
      final due = t.dueDate;
      if (due == null) return includeNoDueDate;
      return !due.isBefore(start) && due.isBefore(end);
    });
  }

  Iterable<Task> dueToday({DateTime? now, bool includeNoDueDate = false}) =>
      dueOnDay(now ?? DateTime.now(), includeNoDueDate: includeNoDueDate);

  Iterable<Task> dueThisWeek({
    DateTime? now,
    int weekStartsOn = DateTime.monday,
    bool includeNoDueDate = false,
  }) {
    final ref = now ?? DateTime.now();
    final start = _startOfWeek(ref, weekStartsOn: weekStartsOn);
    final end = start.add(const Duration(days: 7));
    return where((t) {
      final due = t.dueDate;
      if (due == null) return includeNoDueDate;
      return !due.isBefore(start) && due.isBefore(end);
    });
  }

  Map<String, List<Task>> groupByProjectId({
    String unassignedKey = 'unassigned',
  }) =>
      fold(<String, List<Task>>{}, (acc, t) {
        final key = t.project?.id ?? unassignedKey;
        final next = (acc[key] ?? const <Task>[])
            .toList(growable: true)
          ..add(t);
        return {...acc, key: next};
      });

  Map<TaskStatus, int> countByStatus() => fold({
        for (final s in TaskStatus.values) s: 0,
      }, (acc, t) => {...acc, t.status: (acc[t.status] ?? 0) + 1});

  int overdueCount({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return fold<int>(0, (count, t) {
      final due = t.dueDate;
      final overdue =
          due != null && due.isBefore(ref) && t.status != TaskStatus.done;
      return count + (overdue ? 1 : 0);
    });
  }

  TaskStats stats({DateTime? now, int weekStartsOn = DateTime.monday}) {
    final ref = now ?? DateTime.now();
    final byStatus = countByStatus();
    return TaskStats(
      total: length,
      byStatus: byStatus,
      overdue: overdueCount(now: ref),
      dueToday: dueToday(now: ref).length,
      dueThisWeek: dueThisWeek(now: ref, weekStartsOn: weekStartsOn).length,
    );
  }
}

class TaskStats {
  const TaskStats({
    required this.total,
    required this.byStatus,
    required this.overdue,
    required this.dueToday,
    required this.dueThisWeek,
  });

  final int total;
  final Map<TaskStatus, int> byStatus;
  final int overdue;
  final int dueToday;
  final int dueThisWeek;
}

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime _startOfWeek(DateTime dt, {required int weekStartsOn}) {
  final dayStart = _startOfDay(dt);
  final weekday = dayStart.weekday;
  final delta = (weekday - weekStartsOn) % 7;
  return dayStart.subtract(Duration(days: delta));
}

