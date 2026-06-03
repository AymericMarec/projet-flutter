import 'package:flutter/material.dart';

import '../../core/extensions/color_extensions.dart';
import '../../domain/entities/task.dart';
import '../../domain/extensions/task_extensions.dart';

class TaskDetailView extends StatelessWidget {
  const TaskDetailView({
    super.key,
    required this.task,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final Task task;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = task.project;
    final dueDateLabel = task.dueDateLabel();
    final overdue = task.isOverdue();

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Retour',
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  icon: Icons.assignment_turned_in_outlined,
                  label: _statusLabel(task.status),
                ),
                _InfoChip(
                  icon: Icons.flag_outlined,
                  label: _priorityLabel(task.priority),
                ),
                _InfoChip(
                  icon: Icons.event,
                  label: dueDateLabel,
                  tone: overdue ? theme.colorScheme.error : null,
                ),
                _InfoChip(
                  icon: Icons.folder_outlined,
                  label: project?.name ?? 'Aucun projet',
                  dotColor: project?.colorValue.toColorOrNull(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Description', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              (task.description == null || task.description!.trim().isEmpty)
                  ? '—'
                  : task.description!.trim(),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Text('Changer le statut', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in TaskStatus.values)
                  ChoiceChip(
                    label: Text(_statusLabel(s)),
                    selected: task.status == s,
                    onSelected: (_) => onStatusChanged(s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.dotColor,
    this.tone,
  });

  final IconData icon;
  final String label;
  final Color? dotColor;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(TaskStatus status) => switch (status) {
      TaskStatus.todo => 'TODO',
      TaskStatus.inProgress => 'En cours',
      TaskStatus.done => 'Terminé',
    };

String _priorityLabel(TaskPriority priority) => switch (priority) {
      TaskPriority.low => 'Faible',
      TaskPriority.medium => 'Moyenne',
      TaskPriority.high => 'Haute',
      TaskPriority.urgent => 'Urgente',
    };

