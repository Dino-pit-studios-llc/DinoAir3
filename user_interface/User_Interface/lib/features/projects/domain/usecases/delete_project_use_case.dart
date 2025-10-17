import '../project_repository.dart';

class DeleteProjectUseCase {
  const DeleteProjectUseCase(this._repository);

  final ProjectRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteProject(id);
  }
}
