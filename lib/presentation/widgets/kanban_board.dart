import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';
import 'task_card.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.onTaskSelected,
    required this.onTaskDeleteRequested,
    required this.onTaskStatusChanged,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<Task> onTaskDeleteRequested;
  final void Function(Task task, TaskStatus status) onTaskStatusChanged;

  @override
  Widget build(BuildContext context) {
    final grouped = <TaskStatus, List<Task>>{
      for (final s in TaskStatus.values) s: <Task>[],
    };
    for (final t in tasks) {
      grouped[t.status]!.add(t);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;
        final children = <Widget>[
          for (final status in TaskStatus.values)
            _KanbanColumn(
              status: status,
              tasks: grouped[status]!,
              onTaskSelected: onTaskSelected,
              onTaskDeleteRequested: onTaskDeleteRequested,
              onTaskStatusChanged: onTaskStatusChanged,
            ),
        ];

        if (isNarrow) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: children
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: c,
                    ))
                .toList(growable: false),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children
                .map(
                  (c) => Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: c,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.onTaskSelected,
    required this.onTaskDeleteRequested,
    required this.onTaskStatusChanged,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final ValueChanged<Task> onTaskSelected;
  final ValueChanged<Task> onTaskDeleteRequested;
  final void Function(Task task, TaskStatus status) onTaskStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (status) {
      TaskStatus.todo => 'TODO',
      TaskStatus.inProgress => 'En cours',
      TaskStatus.done => 'Terminé',
    };

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        onTaskStatusChanged(details.data, status);
      },
      builder: (context, candidates, rejected) {
        final highlight = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: tasks.isEmpty
                      ? Align(
                          key: const ValueKey('empty'),
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Déposez une tâche ici.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          key: const ValueKey('list'),
                          padding: EdgeInsets.zero,
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final t = tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Draggable<Task>(
                                data: t,
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                feedback: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 340),
                                  child: Opacity(
                                    opacity: 0.92,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: TaskCard(task: t, onTap: () {}),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.35,
                                  child: TaskCard(
                                    task: t,
                                    onTap: () => onTaskSelected(t),
                                  ),
                                ),
                                child: TaskCard(
                                  task: t,
                                  onTap: () => onTaskSelected(t),
                                  onEdit: () => onTaskSelected(t),
                                  onDelete: () => onTaskDeleteRequested(t),
                                  onStatusChanged: (s) =>
                                      onTaskStatusChanged(t, s),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

