import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/file_search_repository.dart';

class RemoveWatchedDirectoryParams {
  final String path;

  const RemoveWatchedDirectoryParams({required this.path});
}

class RemoveWatchedDirectoryUseCase
    implements UseCase<void, RemoveWatchedDirectoryParams> {
  final FileSearchRepository repository;

  RemoveWatchedDirectoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    RemoveWatchedDirectoryParams params,
  ) async {
    if (params.path.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Directory path cannot be empty'));
    }

    return await repository.removeWatchedDirectory(path: params.path.trim());
  }
}
