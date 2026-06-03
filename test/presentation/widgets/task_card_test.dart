import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_app/domain/entities/task.dart';
import 'package:final_app/presentation/widgets/task_card.dart';

void main() {
  testWidgets('TaskCard displays task details correctly', (WidgetTester tester) async {
    final task = Task(
      id: 't1',
      title: 'Test Title',
      description: 'Test Description',
      priority: TaskPriority.high,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(task: task),
        ),
      ),
    );

    // Vérifie le titre
    expect(find.text('Test Title'), findsOneWidget);
    
    // Vérifie la description
    expect(find.text('Test Description'), findsOneWidget);
    
    // Vérifie le libellé de la priorité
    expect(find.text('Haute'), findsOneWidget);
    
    // Vérifie le statut
    expect(find.text('TODO'), findsOneWidget);
  });
}
