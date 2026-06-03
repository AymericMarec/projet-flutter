import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/extensions/color_extensions.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/task.dart';
import '../providers/app_providers.dart';
import '../widgets/kanban_board.dart';
import '../widgets/project_create_dialog.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_view.dart';
import '../widgets/task_upsert_dialog.dart';

enum NavSection { projects, today, week, settings }
enum TaskViewMode { list, kanban }

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, required this.section});

  final NavSection section;

  String _newTaskId() => 't${DateTime.now().microsecondsSinceEpoch}';
  String _newProjectId() => 'p${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final searchTerm = ref.watch(searchTermProvider);
    final taskViewMode = ref.watch(taskViewModeProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_sectionTitle(section)),
        actions: [
          if (section != NavSection.settings)
            FilledButton.tonalIcon(
              onPressed: () {
                ref.read(taskViewModeProvider.notifier).state =
                    taskViewMode == TaskViewMode.kanban
                    ? TaskViewMode.list
                    : TaskViewMode.kanban;
              },
              icon: Icon(
                taskViewMode == TaskViewMode.kanban
                    ? Icons.view_agenda_outlined
                    : Icons.view_kanban_outlined,
              ),
              label: Text(taskViewMode == TaskViewMode.kanban ? 'Liste' : 'Kanban'),
            ),
          IconButton(
            tooltip: 'Thème',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            tooltip: 'Recharger',
            onPressed: () {
              ref.read(tasksNotifierProvider.notifier).refresh();
              ref.invalidate(projectsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: section == NavSection.settings
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final projects = projectsAsync.valueOrNull ?? const <Project>[];
                final data = await showDialog<TaskUpsertData?>(
                  context: context,
                  builder: (context) => TaskUpsertDialog(projects: projects),
                );
                if (data == null) return;
                await ref.read(tasksNotifierProvider.notifier).create(
                  Task(
                    id: _newTaskId(),
                    title: data.title,
                    description: data.description,
                    priority: data.priority,
                    status: data.status,
                    dueDate: data.dueDate,
                    project: data.project,
                    createdAt: DateTime.now(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tâche'),
            ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Erreur de chargement des tâches: $error',
          onRetry: () => ref.read(tasksNotifierProvider.notifier).refresh(),
        ),
        data: (tasks) => projectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: 'Erreur de chargement des projets: $error',
            onRetry: () => ref.invalidate(projectsProvider),
          ),
          data: (projects) {
            if (section == NavSection.settings) {
              return const _SettingsView();
            }

            final visibleTasks = ref.watch(visibleTasksProvider(section));
            Task? selectedTask;
            if (selectedTaskId != null) {
              for (final task in tasks) {
                if (task.id == selectedTaskId) {
                  selectedTask = task;
                  break;
                }
              }
            }

            if (selectedTask != null) {
              final currentTask = selectedTask;
              return TaskDetailView(
                task: currentTask,
                onClose: () => ref.read(selectedTaskIdProvider.notifier).state = null,
                onEdit: () async {
                  final data = await showDialog<TaskUpsertData?>(
                    context: context,
                    builder: (context) => TaskUpsertDialog(
                      projects: projects,
                      initialTask: currentTask,
                    ),
                  );
                  if (data == null) return;
                  await ref.read(tasksNotifierProvider.notifier).updateTask(
                    currentTask.copyWith(
                      title: data.title,
                      description: data.description,
                      priority: data.priority,
                      status: data.status,
                      dueDate: data.dueDate,
                      project: data.project,
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await _confirmDeletion(context, currentTask);
                  if (confirmed != true) return;
                  await ref
                      .read(tasksNotifierProvider.notifier)
                      .deleteById(currentTask.id);
                  ref.read(selectedTaskIdProvider.notifier).state = null;
                },
                onStatusChanged: (status) {
                  ref
                      .read(tasksNotifierProvider.notifier)
                      .updateTask(currentTask.copyWith(status: status));
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(tasksNotifierProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (section == NavSection.projects) ...[
                    Text('Projets', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tous'),
                          selected: selectedProjectId == null,
                          onSelected: (_) =>
                              ref.read(selectedProjectIdProvider.notifier).state = null,
                        ),
                        for (final project in projects)
                          ChoiceChip(
                            label: Text(project.name),
                            avatar: CircleAvatar(
                              backgroundColor: project.colorValue.toColor(),
                            ),
                            selected: selectedProjectId == project.id,
                            onSelected: (_) => ref
                                .read(selectedProjectIdProvider.notifier)
                                .state = project.id,
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter un projet'),
                          onPressed: () async {
                            final data = await showDialog<ProjectCreateData?>(
                              context: context,
                              builder: (context) => const ProjectCreateDialog(),
                            );
                            if (data == null) return;
                            final repo = ref.read(projectRepositoryProvider);
                            await repo.create(
                              Project(
                                id: _newProjectId(),
                                name: data.name,
                                colorValue: data.color.toARGB32(),
                              ),
                            );
                            ref.invalidate(projectsProvider);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    onChanged: (value) =>
                        ref.read(searchTermProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Rechercher (titre, description, projet)…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchTerm.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () =>
                                  ref.read(searchTermProvider.notifier).state = '',
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in TaskStatus.values)
                        FilterChip(
                          label: Text(_statusLabel(status)),
                          selected:
                              ref.watch(statusFilterProvider).contains(status),
                          onSelected: (selected) {
                            final next = {...ref.read(statusFilterProvider)};
                            if (selected) {
                              next.add(status);
                            } else {
                              next.remove(status);
                            }
                            ref.read(statusFilterProvider.notifier).state = next;
                          },
                        ),
                      TextButton(
                        onPressed: () => ref.read(statusFilterProvider.notifier).state =
                            {...TaskStatus.values},
                        child: const Text('Tout'),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(statusFilterProvider.notifier).state = {},
                        child: const Text('Aucun'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (visibleTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucune tâche ne correspond aux filtres.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (taskViewMode == TaskViewMode.kanban)
                    SizedBox(
                      height: 560,
                      child: KanbanBoard(
                        tasks: visibleTasks,
                        onTaskSelected: (task) =>
                            ref.read(selectedTaskIdProvider.notifier).state = task.id,
                        onTaskDeleteRequested: (task) async {
                          final confirmed = await _confirmDeletion(context, task);
                          if (confirmed != true) return;
                          await ref
                              .read(tasksNotifierProvider.notifier)
                              .deleteById(task.id);
                        },
                        onTaskStatusChanged: (task, status) => ref
                            .read(tasksNotifierProvider.notifier)
                            .updateTask(task.copyWith(status: status)),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final task in visibleTasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              task: task,
                              onTap: () =>
                                  ref.read(selectedTaskIdProvider.notifier).state = task.id,
                              onEdit: () =>
                                  ref.read(selectedTaskIdProvider.notifier).state = task.id,
                              onDelete: () async {
                                final confirmed = await _confirmDeletion(context, task);
                                if (confirmed != true) return;
                                await ref
                                    .read(tasksNotifierProvider.notifier)
                                    .deleteById(task.id);
                              },
                              onStatusChanged: (status) => ref
                                  .read(tasksNotifierProvider.notifier)
                                  .updateTask(task.copyWith(status: status)),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _sectionTitle(NavSection section) => switch (section) {
  NavSection.projects => 'Projets',
  NavSection.today => 'Aujourd’hui',
  NavSection.week => 'Cette semaine',
  NavSection.settings => 'Paramètres',
};

String _statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.todo => 'TODO',
  TaskStatus.inProgress => 'En cours',
  TaskStatus.done => 'Terminé',
};

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _SettingsView extends ConsumerWidget {
  const _SettingsView();

  static const _availableColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorSeed = ref.watch(colorSeedProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Paramètres', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apparence', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Thème'),
                  subtitle: const Text('Choisissez le mode d\'affichage'),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Clair'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Sombre'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref.read(themeModeProvider.notifier).setMode(newSelection.first);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Couleur d\'accentuation'),
                  subtitle: const Text('Personnalisez la couleur principale de l\'application'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableColors.map((color) {
                      final isSelected = color.value == colorSeed.value;
                      return InkWell(
                        onTap: () => ref.read(colorSeedProvider.notifier).setColor(color),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Données', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Exporter les tâches'),
                  subtitle: const Text('Sauvegarder les tâches dans un fichier JSON'),
                  onTap: () async {
                    final jsonString = await ref.read(tasksNotifierProvider.notifier).exportTasksToJson();
                    final path = await FilePicker.saveFile(
                      dialogTitle: 'Exporter les tâches',
                      fileName: 'tasks_export.json',
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (path != null) {
                      await File(path).writeAsString(jsonString);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tâches exportées avec succès.')));
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Importer des tâches'),
                  subtitle: const Text('Charger les tâches depuis un fichier JSON'),
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      dialogTitle: 'Importer des tâches',
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.single.path != null) {
                      try {
                        final file = File(result.files.single.path!);
                        final jsonString = await file.readAsString();
                        final jsonList = jsonDecode(jsonString) as List<dynamic>;
                        await ref.read(tasksNotifierProvider.notifier).importTasksFromJson(jsonList);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tâches importées avec succès.')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'import : $e")));
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool?> _confirmDeletion(BuildContext context, Task task) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la tâche ?'),
      content: Text('“${task.title}” sera supprimée définitivement.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
