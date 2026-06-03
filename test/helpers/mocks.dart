import 'package:mockito/annotations.dart';
import 'package:final_app/domain/repositories/task_repository.dart';
import 'package:final_app/domain/repositories/project_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([
  TaskRepository,
  ProjectRepository,
  SharedPreferences,
])
void main() {}
