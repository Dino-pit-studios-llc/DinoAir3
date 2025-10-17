import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/file_search_repository.dart';

class AddWatchedDirectoryParams {
  final String path;
  final bool includeSubdirectories;
  final List<String>? fileExtensions;

  const AddWatchedDirectoryParams({
    required this.path,
    this.includeSubdirectories = true,
    this.fileExtensions,
  });
}

class AddWatchedDirectoryUseCase
    implements UseCase<void, AddWatchedDirectoryParams> {
  final FileSearchRepository repository;

  AddWatchedDirectoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    AddWatchedDirectoryParams params,
  ) async {
    // Validate path
    if (params.path.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Directory path cannot be empty'));
    }

    // Validate file extensions if provided
    if (params.fileExtensions != null &&
        params.fileExtensions!.any((ext) => ext.trim().isEmpty)) {
      return const Left(ValidationFailure(message: 'File extensions cannot be empty'));
    }

    return await repository.addWatchedDirectory(
      path: params.path.trim(),
      includeSubdirectories: params.includeSubdirectories,
      fileExtensions: params.fileExtensions
          ?.map((ext) => ext.trim().toLowerCase())
          .where((ext) => ext.isNotEmpty)
          .toList(),
    );
  }
}
