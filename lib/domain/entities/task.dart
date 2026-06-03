import 'package:freezed_annotation/freezed_annotation.dart';

import 'project.dart';

part 'task.freezed.dart';
part 'task.g.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  todo,
  inProgress,
  done,
}

@freezed
abstract class Task with _$Task {
  factory Task({
    required String id,
    required String title,
    String? description,
    @Default(TaskPriority.medium) TaskPriority priority,
    @Default(TaskStatus.todo) TaskStatus status,
    DateTime? dueDate,
    Project? project,
    required DateTime createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
