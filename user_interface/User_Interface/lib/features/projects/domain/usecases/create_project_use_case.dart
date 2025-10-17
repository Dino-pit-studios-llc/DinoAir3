import '../project_entity.dart';
import '../project_repository.dart';

class CreateProjectUseCase {
  const CreateProjectUseCase(this._repository);

  final ProjectRepository _repository;

  Future<ProjectEntity> call(ProjectEntity project) {
    return _repository.createProject(project);
  }
}
