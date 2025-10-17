import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/file_search_repository.dart';

class ReindexAllUseCase implements UseCase<void, NoParams> {
  final FileSearchRepository repository;

  ReindexAllUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.reindexAll();
  }
}
