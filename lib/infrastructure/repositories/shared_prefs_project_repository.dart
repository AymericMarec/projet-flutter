import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class SharedPrefsProjectRepository implements ProjectRepository {
  SharedPrefsProjectRepository(this._sharedPreferences)
    : _projects = _readProjects(_sharedPreferences) ?? <Project>[] {
    if (!_sharedPreferences.containsKey(_storageKey)) {
      _persist();
    }
  }

  static const String _storageKey = 'projects';

  final SharedPreferences _sharedPreferences;
  final List<Project> _projects;

  @override
  Future<Project> create(Project project) async {
    _projects.add(project);
    await _persist();
    return project;
  }

  @override
  Future<void> deleteById(String id) async {
    _projects.removeWhere((project) => project.id == id);
    await _persist();
  }

  @override
  Future<List<Project>> findAll() async => List<Project>.unmodifiable(_projects);

  @override
  Future<Project?> findById(String id) async {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  @override
  Future<Project> update(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index == -1) {
      throw StateError('Project not found: ${project.id}');
    }
    _projects[index] = project;
    await _persist();
    return project;
  }

  Future<void> _persist() async {
    final serialized = _projects.map((project) => jsonEncode(project.toJson())).toList();
    await _sharedPreferences.setStringList(_storageKey, serialized);
  }

  static List<Project>? _readProjects(SharedPreferences sharedPreferences) {
    final serialized = sharedPreferences.getStringList(_storageKey);
    if (serialized == null) return null;
    return serialized
        .map((projectJson) => Project.fromJson(jsonDecode(projectJson) as Map<String, dynamic>))
        .toList();
  }
}
