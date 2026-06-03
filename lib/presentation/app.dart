import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'dart:io';

import '../domain/entities/task.dart';
import '../core/theme/app_theme.dart';
import 'providers/app_providers.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  bool _hasCheckedOverdue = false;

  @override
  void initState() {
    super.initState();
    if (!const bool.fromEnvironment('dart.library.html') &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!const bool.fromEnvironment('dart.library.html') &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _checkOverdueTasks(List<Task> tasks) {
    if (_hasCheckedOverdue) return;
    _hasCheckedOverdue = true;

    final now = DateTime.now();
    final overdueTasks = tasks.where((t) =>
        t.status != TaskStatus.done &&
        t.dueDate != null &&
        t.dueDate!.isBefore(DateTime(now.year, now.month, now.day))).toList();

    if (overdueTasks.isNotEmpty) {
      final notification = LocalNotification(
        title: 'Tâches en retard',
        body: 'Vous avez ${overdueTasks.length} tâche(s) en retard !',
      );
      notification.show();
    }
  }

  @override
  void onWindowClose() async {
    final todayTasks = ref.read(todayTasksProvider);
    final hasPendingToday = todayTasks.any((t) => t.status != TaskStatus.done);

    if (hasPendingToday) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quitter ?'),
          content: const Text('Vous avez encore des tâches non terminées pour aujourd\'hui. Voulez-vous vraiment quitter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (shouldClose == true) {
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the tasks to trigger the overdue check once they are loaded
    ref.listen(tasksNotifierProvider, (previous, next) {
      if (next.value != null) {
        _checkOverdueTasks(next.value!);
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final colorSeed = ref.watch(colorSeedProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gestion des taches',
      themeMode: themeMode,
      theme: AppTheme.lightTheme(colorSeed),
      darkTheme: AppTheme.darkTheme(colorSeed),
      routerConfig: appRouter.config(),
    );
  }
}

