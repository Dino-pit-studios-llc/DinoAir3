import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/directory_config.dart';
import '../repositories/file_search_repository.dart';

class GetWatchedDirectoriesUseCase
    implements UseCase<List<DirectoryConfig>, NoParams> {
  final FileSearchRepository repository;

  GetWatchedDirectoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<DirectoryConfig>>> call(NoParams params) async {
    return await repository.getWatchedDirectories();
  }
}
