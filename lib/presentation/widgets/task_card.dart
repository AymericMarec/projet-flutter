import 'package:flutter/material.dart';

import '../../core/extensions/color_extensions.dart';
import '../../domain/entities/task.dart';
import '../../domain/extensions/task_extensions.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onStatusChanged,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ValueChanged<TaskStatus>? onStatusChanged;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  Future<void> _showContextMenu(Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final action = await showMenu<_TaskMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: _TaskMenuAction.open,
          child: Row(
            children: [
              Icon(Icons.open_in_new),
              SizedBox(width: 10),
              Text('Ouvrir (détails)'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _TaskMenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 10),
              Text('Modifier'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Text('Changer le statut'),
        ),
        const PopupMenuItem(
          value: _TaskMenuAction.statusTodo,
          child: Text('TODO'),
        ),
        const PopupMenuItem(
          value: _TaskMenuAction.statusInProgress,
          child: Text('En cours'),
        ),
        const PopupMenuItem(
          value: _TaskMenuAction.statusDone,
          child: Text('Terminé'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _TaskMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 10),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    );

    switch (action) {
      case null:
        return;
      case _TaskMenuAction.open:
        widget.onTap?.call();
      case _TaskMenuAction.edit:
        widget.onEdit?.call();
      case _TaskMenuAction.statusTodo:
        widget.onStatusChanged?.call(TaskStatus.todo);
      case _TaskMenuAction.statusInProgress:
        widget.onStatusChanged?.call(TaskStatus.inProgress);
      case _TaskMenuAction.statusDone:
        widget.onStatusChanged?.call(TaskStatus.done);
      case _TaskMenuAction.delete:
        widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final priorityColor = _priorityColor(task.priority);
    final (statusLabel, statusColor) = _statusStyle(task.status);
    final dueDateLabel = task.dueDateLabel();
    final overdue = task.isOverdue();
    final project = task.project;

    final theme = Theme.of(context);
    final hoverTint = theme.colorScheme.primary.withValues(alpha: 0.06);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _showContextMenu(details.globalPosition),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          elevation: _hovered ? 4 : 1,
          color: theme.colorScheme.surface,
          shadowColor: theme.shadowColor,
          borderRadius: BorderRadius.circular(12),
          shape: BoxShape.rectangle,
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: _hovered ? hoverTint : theme.colorScheme.surface,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: () {
                if (widget.onDelete == null &&
                    widget.onEdit == null &&
                    widget.onStatusChanged == null) {
                  return;
                }
                final box = context.findRenderObject() as RenderBox?;
                final pos = box?.localToGlobal(const Offset(24, 24));
                if (pos == null) return;
                _showContextMenu(pos);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatusPill(
                                label: statusLabel,
                                color: statusColor,
                              ),
                              if (widget.onDelete != null ||
                                  widget.onEdit != null ||
                                  widget.onStatusChanged != null) ...[
                                const SizedBox(width: 4),
                                Builder(
                                  builder: (buttonContext) => IconButton(
                                    tooltip: 'Actions',
                                    onPressed: () {
                                      final box = buttonContext
                                          .findRenderObject() as RenderBox?;
                                      if (box == null) return;
                                      final pos = box.localToGlobal(
                                        box.size.center(Offset.zero),
                                      );
                                      _showContextMenu(pos);
                                    },
                                    icon: const Icon(Icons.more_vert),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (project != null) ...[
                            const SizedBox(height: 8),
                            _ProjectPill(
                              projectName: project.name,
                              color: project.colorValue.toColor(),
                            ),
                          ],
                          if (task.description != null &&
                              task.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.description!.trim(),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.flag,
                                size: 16,
                                color: priorityColor.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _priorityLabel(task.priority),
                                  style: theme.textTheme.labelLarge,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.event,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  dueDateLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: overdue
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TaskMenuAction {
  open,
  edit,
  statusTodo,
  statusInProgress,
  statusDone,
  delete,
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProjectPill extends StatelessWidget {
  const _ProjectPill({required this.projectName, required this.color});

  final String projectName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            projectName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

Color _priorityColor(TaskPriority priority) => switch (priority) {
      TaskPriority.low => Colors.grey,
      TaskPriority.medium => Colors.blue,
      TaskPriority.high => Colors.orange,
      TaskPriority.urgent => Colors.red,
    };

String _priorityLabel(TaskPriority priority) => switch (priority) {
      TaskPriority.low => 'Faible',
      TaskPriority.medium => 'Moyenne',
      TaskPriority.high => 'Haute',
      TaskPriority.urgent => 'Urgente',
    };

(String, Color) _statusStyle(TaskStatus status) => switch (status) {
      TaskStatus.todo => ('TODO', Colors.grey),
      TaskStatus.inProgress => ('En cours', Colors.amber),
      TaskStatus.done => ('Terminé', Colors.green),
    };

