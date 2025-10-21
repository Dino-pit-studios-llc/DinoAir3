import 'project_entity.dart';

abstract class ProjectRepository {
  Future<ProjectEntity> createProject(ProjectEntity project);
  Future<ProjectEntity> getProject(String id);
  Future<List<ProjectEntity>> listProjects(
      {String? statusFilter, String? parentId});
  Future<ProjectEntity> updateProject(ProjectEntity project);
  Future<void> deleteProject(String id);
  Future<List<ProjectEntity>> getChildProjects(String parentId);
}
