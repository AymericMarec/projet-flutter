import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:final_app/domain/entities/task.dart';
import 'package:final_app/presentation/providers/app_providers.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockTaskRepository mockTaskRepository;

  setUp(() {
    mockTaskRepository = MockTaskRepository();
  });

  test('TasksNotifier loads tasks via a mocked repository', () async {
    final tasks = [
      Task(
        id: 't1',
        title: 'Task 1',
        description: 'Desc 1',
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      )
    ];

    when(mockTaskRepository.findAll()).thenAnswer((_) async => tasks);

    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockTaskRepository),
      ],
    );

    addTearDown(container.dispose);

    // Read the future to trigger build and wait for it
    final result = await container.read(tasksNotifierProvider.future);

    expect(result, equals(tasks));
    verify(mockTaskRepository.findAll()).called(1);
  });

  test('TasksNotifier adds a task and refreshes via ProviderContainer overrides', () async {
    final tasks = [
      Task(
        id: 't1',
        title: 'Task 1',
        description: 'Desc 1',
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      )
    ];

    final newTask = Task(
      id: 't2',
      title: 'Task 2',
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
    );

    when(mockTaskRepository.findAll()).thenAnswer((_) async => tasks);
    when(mockTaskRepository.create(newTask)).thenAnswer((_) async => newTask);

    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockTaskRepository),
      ],
    );

    addTearDown(container.dispose);

    // Wait for the initial build
    await container.read(tasksNotifierProvider.future);

    // Update the mock to return the new list after creation
    when(mockTaskRepository.findAll()).thenAnswer((_) async => [...tasks, newTask]);

    // Create the new task using the notifier
    await container.read(tasksNotifierProvider.notifier).create(newTask);

    final result = await container.read(tasksNotifierProvider.future);

    expect(result.length, 2);
    expect(result.contains(newTask), isTrue);

    verify(mockTaskRepository.create(newTask)).called(1);
    // findAll is called once during build, and once during refresh after create
    verify(mockTaskRepository.findAll()).called(2);
  });
}
