import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/file_search_repository.dart';

class AddToIndexParams {
  final String path;
  final bool includeSubdirectories;

  const AddToIndexParams({
    required this.path,
    this.includeSubdirectories = true,
  });
}

class AddToIndexUseCase implements UseCase<void, AddToIndexParams> {
  final FileSearchRepository repository;

  AddToIndexUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddToIndexParams params) async {
    // Validate path
    if (params.path.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Path cannot be empty'));
    }

    return await repository.addToIndex(
      path: params.path.trim(),
      includeSubdirectories: params.includeSubdirectories,
    );
  }
}
