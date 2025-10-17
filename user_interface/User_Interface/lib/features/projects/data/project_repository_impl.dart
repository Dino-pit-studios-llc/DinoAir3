import '../../../core/errors/error_handler.dart';
import '../domain/project_entity.dart';
import '../domain/project_repository.dart';
import 'project_mapper.dart';
import 'project_remote_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._remoteDataSource);

  final ProjectRemoteDataSource _remoteDataSource;

  @override
  Future<ProjectEntity> createProject(ProjectEntity project) {
    return guardFuture(() async {
      final dto = ProjectMapper.fromEntity(project);
      final created = await _remoteDataSource.createProject(dto);
      return ProjectMapper.toEntity(created);
    });
  }

  @override
  Future<void> deleteProject(String id) {
    return guardFuture(() => _remoteDataSource.deleteProject(id));
  }

  @override
  Future<ProjectEntity> getProject(String id) {
    return guardFuture(() async {
      final dto = await _remoteDataSource.fetchProject(id);
      return ProjectMapper.toEntity(dto);
    });
  }

  @override
  Future<List<ProjectEntity>> listProjects({
    String? statusFilter,
    String? parentId,
  }) {
    return guardFuture(() async {
      final params = <String, dynamic>{};
      if (statusFilter != null) params['status_filter'] = statusFilter;
      if (parentId != null) params['parent_id'] = parentId;

      final dtos = await _remoteDataSource.fetchProjects(
        queryParameters: params.isEmpty ? null : params,
      );
      return ProjectMapper.toEntities(dtos);
    });
  }

  @override
  Future<ProjectEntity> updateProject(ProjectEntity project) {
    return guardFuture(() async {
      final dto = ProjectMapper.fromEntity(project);
      final updated = await _remoteDataSource.updateProject(dto);
      return ProjectMapper.toEntity(updated);
    });
  }

  @override
  Future<List<ProjectEntity>> getChildProjects(String parentId) {
    return guardFuture(() async {
      final dtos = await _remoteDataSource.fetchChildProjects(parentId);
      return ProjectMapper.toEntities(dtos);
    });
  }
}
