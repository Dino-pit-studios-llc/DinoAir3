import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/file_search_repository.dart';

class RemoveFromIndexParams {
  final String path;

  const RemoveFromIndexParams({required this.path});
}

class RemoveFromIndexUseCase implements UseCase<void, RemoveFromIndexParams> {
  final FileSearchRepository repository;

  RemoveFromIndexUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromIndexParams params) async {
    // Validate path
    if (params.path.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Path cannot be empty'));
    }

    return await repository.removeFromIndex(path: params.path.trim());
  }
}
