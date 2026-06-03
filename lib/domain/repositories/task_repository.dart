import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> findAll();
  Future<Task?> findById(String id);
  Future<Task> create(Task task);
  Future<Task> update(Task task);
  Future<void> deleteById(String id);
}
