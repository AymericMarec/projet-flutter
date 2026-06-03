import '../entities/task.dart';

extension DateFormattingX on DateTime {
  String toFrShortDate() =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  DateTime startOfDay() => DateTime(year, month, day);
}

extension TaskX on Task {
  bool isOverdue({DateTime? now}) {
    if (status == TaskStatus.done) return false;
    if (dueDate == null) return false;
    final ref = now ?? DateTime.now();
    return dueDate!.isBefore(ref);
  }

  String dueDateLabel() =>
      dueDate == null ? 'Aucune' : dueDate!.toFrShortDate();
}

