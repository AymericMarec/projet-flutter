import 'package:flutter/material.dart';

import '../../core/extensions/color_extensions.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/task.dart';

class TaskUpsertData {
  const TaskUpsertData({
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.project,
    required this.dueDate,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final Project? project;
  final DateTime? dueDate;
}

class TaskUpsertDialog extends StatefulWidget {
  const TaskUpsertDialog({
    super.key,
    required this.projects,
    this.initialTask,
  });

  final List<Project> projects;
  final Task? initialTask;

  @override
  State<TaskUpsertDialog> createState() => _TaskUpsertDialogState();
}

class _TaskUpsertDialogState extends State<TaskUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskPriority _priority;
  late TaskStatus _status;
  Project? _project;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.todo;
    _project = t?.project;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  void _clearDueDate() => setState(() => _dueDate = null);

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final title = _titleController.text.trim();
    final rawDescription = _descriptionController.text.trim();
    final description = rawDescription.isEmpty ? null : rawDescription;

    Navigator.of(context).pop(
      TaskUpsertData(
        title: title,
        description: description,
        priority: _priority,
        status: _status,
        project: _project,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialTask != null;
    final theme = Theme.of(context);
    final dueDateLabel = _dueDate == null
        ? 'Aucune'
        : MaterialLocalizations.of(context).formatMediumDate(_dueDate!);

    return AlertDialog(
      title: Text(editing ? 'Modifier la tâche' : 'Nouvelle tâche'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est obligatoire.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<TaskPriority>(
                        initialSelection: _priority,
                        onSelected: (v) {
                          if (v == null) return;
                          setState(() => _priority = v);
                        },
                        label: const Text('Priorité'),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(
                            value: TaskPriority.low,
                            label: 'Faible',
                          ),
                          DropdownMenuEntry(
                            value: TaskPriority.medium,
                            label: 'Moyenne',
                          ),
                          DropdownMenuEntry(
                            value: TaskPriority.high,
                            label: 'Haute',
                          ),
                          DropdownMenuEntry(
                            value: TaskPriority.urgent,
                            label: 'Urgente',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownMenu<TaskStatus>(
                        initialSelection: _status,
                        onSelected: (v) {
                          if (v == null) return;
                          setState(() => _status = v);
                        },
                        label: const Text('Statut'),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(
                            value: TaskStatus.todo,
                            label: 'TODO',
                          ),
                          DropdownMenuEntry(
                            value: TaskStatus.inProgress,
                            label: 'En cours',
                          ),
                          DropdownMenuEntry(
                            value: TaskStatus.done,
                            label: 'Terminé',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownMenu<Project?>(
                  initialSelection: _project,
                  onSelected: (p) => setState(() => _project = p),
                  label: const Text('Projet associé'),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<Project?>(
                      value: null,
                      label: 'Aucun',
                    ),
                    ...widget.projects.map(
                      (p) => DropdownMenuEntry<Project?>(
                        value: p,
                        label: p.name,
                        leadingIcon: CircleAvatar(
                          radius: 6,
                          backgroundColor: p.colorValue.toColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d’échéance',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dueDateLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.event),
                        label: const Text('Choisir'),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: _dueDate == null ? null : _clearDueDate,
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(editing ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}

