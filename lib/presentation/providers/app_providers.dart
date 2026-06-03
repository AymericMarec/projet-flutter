import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/project.dart';
import '../../domain/entities/task.dart';
import '../../domain/extensions/task_list_utils.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../infrastructure/repositories/shared_prefs_project_repository.dart';
import '../../infrastructure/repositories/shared_prefs_task_repository.dart';
import '../pages/dashboard_page.dart';
import '../router/app_router.dart';

final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Doit être overridé au démarrage'),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => SharedPrefsProjectRepository(ref.watch(sharedPreferencesProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => SharedPrefsTaskRepository(ref.watch(sharedPreferencesProvider)),
);

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.findAll();
});

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.findAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(taskRepositoryProvider);
      return repo.findAll();
    });
  }

  Future<void> create(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.create(task);
    await refresh();
  }

  Future<void> updateTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.update(task);
    await refresh();
  }

  Future<void> deleteById(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteById(id);
    await refresh();
  }

  Future<void> importTasksFromJson(List<dynamic> jsonList) async {
    final repo = ref.read(taskRepositoryProvider);
    for (final item in jsonList) {
      if (item is Map<String, dynamic>) {
        final task = Task.fromJson(item);
        // We use update to overwrite if exists, or create if it doesn't
        try {
          await repo.update(task);
        } catch (_) {
          await repo.create(task);
        }
      }
    }
    await refresh();
  }

  Future<String> exportTasksToJson() async {
    final tasks = state.valueOrNull ?? await ref.read(taskRepositoryProvider).findAll();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    return jsonEncode(jsonList);
  }
}

final tasksNotifierProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

final searchTermProvider = StateProvider<String>((ref) => '');

final statusFilterProvider = StateProvider<Set<TaskStatus>>(
  (ref) => {...TaskStatus.values},
);

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);
final taskViewModeProvider =
    StateProvider<TaskViewMode>((ref) => TaskViewMode.kanban);

final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider).valueOrNull ?? const <Task>[];
  return tasks.dueToday().toList(growable: false);
});

final weekTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider).valueOrNull ?? const <Task>[];
  return tasks.dueThisWeek().toList(growable: false);
});

final visibleTasksProvider = Provider.family<List<Task>, NavSection>((ref, section) {
  final tasks = ref.watch(tasksNotifierProvider).valueOrNull ?? const <Task>[];
  final query = ref.watch(searchTermProvider);
  final selectedProjectId = ref.watch(selectedProjectIdProvider);
  final statusFilter = ref.watch(statusFilterProvider);

  Iterable<Task> source = switch (section) {
    NavSection.projects => tasks,
    NavSection.today => ref.watch(todayTasksProvider),
    NavSection.week => ref.watch(weekTasksProvider),
    NavSection.settings => const <Task>[],
  };

  if (selectedProjectId != null && section == NavSection.projects) {
    source = source.where((task) => task.project?.id == selectedProjectId);
  }

  source = source.where((task) => statusFilter.contains(task.status));

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isNotEmpty) {
    source = source.where((task) {
      final title = task.title.toLowerCase();
      final description = (task.description ?? '').toLowerCase();
      final project = (task.project?.name ?? '').toLowerCase();
      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery) ||
          project.contains(normalizedQuery);
    });
  }

  return source.toList(growable: false);
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeModeKey = 'themeMode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final modeString = prefs.getString(_themeModeKey);
    if (modeString != null) {
      return ThemeMode.values.firstWhere((e) => e.name == modeString, orElse: () => ThemeMode.system);
    }
    // Fallback to legacy boolean if present
    final isDarkMode = prefs.getBool('darkMode') ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> toggle() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(nextMode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ColorSeedNotifier extends Notifier<Color> {
  static const _colorSeedKey = 'colorSeed';

  @override
  Color build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final colorValue = prefs.getInt(_colorSeedKey);
    return colorValue != null ? Color(colorValue) : Colors.deepPurple;
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_colorSeedKey, color.toARGB32());
  }
}

final colorSeedProvider = NotifierProvider<ColorSeedNotifier, Color>(ColorSeedNotifier.new);
