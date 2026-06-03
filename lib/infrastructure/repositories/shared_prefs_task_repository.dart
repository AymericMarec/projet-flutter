import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class SharedPrefsTaskRepository implements TaskRepository {
  SharedPrefsTaskRepository(this._sharedPreferences)
    : _tasks = _readTasks(_sharedPreferences) ?? <Task>[] {
    if (!_sharedPreferences.containsKey(_storageKey)) {
      _persist();
    }
  }

  static const String _storageKey = 'tasks';

  final SharedPreferences _sharedPreferences;
  final List<Task> _tasks;

  @override
  Future<Task> create(Task task) async {
    _tasks.add(task);
    await _persist();
    return task;
  }

  @override
  Future<void> deleteById(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await _persist();
  }

  @override
  Future<List<Task>> findAll() async => List<Task>.unmodifiable(_tasks);

  @override
  Future<Task?> findById(String id) async {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  Future<Task> update(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      throw StateError('Task not found: ${task.id}');
    }
    _tasks[index] = task;
    await _persist();
    return task;
  }

  Future<void> _persist() async {
    final serialized = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await _sharedPreferences.setStringList(_storageKey, serialized);
  }

  static List<Task>? _readTasks(SharedPreferences sharedPreferences) {
    final serialized = sharedPreferences.getStringList(_storageKey);
    if (serialized == null) return null;
    return serialized
        .map((taskJson) => Task.fromJson(jsonDecode(taskJson) as Map<String, dynamic>))
        .toList();
  }
}
