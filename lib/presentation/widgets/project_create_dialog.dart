import 'package:flutter/material.dart';

class ProjectCreateData {
  const ProjectCreateData({required this.name, required this.color});

  final String name;
  final Color color;
}

class ProjectCreateDialog extends StatefulWidget {
  const ProjectCreateDialog({super.key});

  @override
  State<ProjectCreateDialog> createState() => _ProjectCreateDialogState();
}

class _ProjectCreateDialogState extends State<ProjectCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _color = Colors.deepPurple;

  static const List<Color> _colors = <Color>[
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    Navigator.of(context).pop(
      ProjectCreateData(name: _nameController.text.trim(), color: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau projet'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              DropdownMenu<Color>(
                initialSelection: _color,
                onSelected: (c) {
                  if (c == null) return;
                  setState(() => _color = c);
                },
                label: const Text('Couleur'),
                dropdownMenuEntries: [
                  for (final c in _colors)
                    DropdownMenuEntry<Color>(
                      value: c,
                      label: _colorLabel(c),
                      leadingIcon: CircleAvatar(radius: 6, backgroundColor: c),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}

String _colorLabel(Color c) {
  if (c == Colors.deepPurple) return 'Violet';
  if (c == Colors.indigo) return 'Indigo';
  if (c == Colors.blue) return 'Bleu';
  if (c == Colors.teal) return 'Turquoise';
  if (c == Colors.green) return 'Vert';
  if (c == Colors.amber) return 'Ambre';
  if (c == Colors.orange) return 'Orange';
  if (c == Colors.red) return 'Rouge';
  if (c == Colors.pink) return 'Rose';
  if (c == Colors.brown) return 'Marron';
  return 'Gris';
}

