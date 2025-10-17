import '../project_entity.dart';
import '../project_repository.dart';

class UpdateProjectUseCase {
  const UpdateProjectUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectEntity> call(ProjectEntity project) {
    return _repository.updateProject(project);
  }
}
