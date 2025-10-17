import '../project_entity.dart';
import '../project_repository.dart';

class GetChildProjectsUseCase {
  const GetChildProjectsUseCase(this._repository);

  final ProjectRepository _repository;

  Future<List<ProjectEntity>> call(String parentId) {
    return _repository.getChildProjects(parentId);
  }
}
