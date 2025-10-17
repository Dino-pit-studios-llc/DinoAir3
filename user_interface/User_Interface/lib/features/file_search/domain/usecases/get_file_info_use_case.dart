import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/file_search_result.dart';
import '../repositories/file_search_repository.dart';

class GetFileInfoParams {
  final String filePath;

  const GetFileInfoParams({required this.filePath});
}

class GetFileInfoUseCase
    implements UseCase<FileSearchResult, GetFileInfoParams> {
  final FileSearchRepository repository;

  GetFileInfoUseCase(this.repository);

  @override
  Future<Either<Failure, FileSearchResult>> call(
    GetFileInfoParams params,
  ) async {
    // Validate file path
    if (params.filePath.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'File path cannot be empty'));
    }

    return await repository.getFileInfo(filePath: params.filePath.trim());
  }
}
