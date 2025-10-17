import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/search_statistics.dart';
import '../repositories/file_search_repository.dart';

class GetSearchStatisticsUseCase
    implements UseCase<SearchStatistics, NoParams> {
  final FileSearchRepository repository;

  GetSearchStatisticsUseCase(this.repository);

  @override
  Future<Either<Failure, SearchStatistics>> call(NoParams params) async {
    return await repository.getSearchStatistics();
  }
}
