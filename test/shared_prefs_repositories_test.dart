import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_app/domain/entities/project.dart';
import 'package:final_app/domain/entities/task.dart';
import 'package:final_app/infrastructure/repositories/shared_prefs_project_repository.dart';
import 'package:final_app/infrastructure/repositories/shared_prefs_task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tasks and projects survive repository restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final projectRepository = SharedPrefsProjectRepository(prefs);
    final taskRepository = SharedPrefsTaskRepository(prefs);

    final project = const Project(
      id: 'p-test',
      name: 'Persistence',
      colorValue: 0xFF112233,
    );
    await projectRepository.create(project);

    final task = Task(
      id: 't-test',
      title: 'Persist me',
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      project: project,
      createdAt: DateTime(2026, 1, 1),
    );
    await taskRepository.create(task);

    final restartedProjectRepository = SharedPrefsProjectRepository(prefs);
    final restartedTaskRepository = SharedPrefsTaskRepository(prefs);

    final projects = await restartedProjectRepository.findAll();
    final tasks = await restartedTaskRepository.findAll();

    expect(projects.any((p) => p.id == 'p-test'), isTrue);
    expect(tasks.any((t) => t.id == 't-test'), isTrue);
  });
}
