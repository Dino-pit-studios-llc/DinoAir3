import '../project_entity.dart';
import '../project_repository.dart';

class ListProjectsUseCase {
  const ListProjectsUseCase(this._repository);

  final ProjectRepository _repository;

  Future<List<ProjectEntity>> call({String? statusFilter, String? parentId}) {
    return _repository.listProjects(
        statusFilter: statusFilter, parentId: parentId);
  }
}
