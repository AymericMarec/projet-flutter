import '../entities/project.dart';
import '../entities/task.dart';

class DashboardData {
  const DashboardData({
    required this.projects,
    required this.tasks,
  });

  final List<Project> projects;
  final List<Task> tasks;
}

