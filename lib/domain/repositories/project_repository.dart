import '../entities/project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> findAll();
  Future<Project?> findById(String id);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
  Future<void> deleteById(String id);
}
