import 'package:dartz/dartz.dart';
import '../entities/file_search_result.dart';
import '../repositories/file_search_repository.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/usecase.dart';

class SearchFilesParams {
  final String query;
  final List<String>? fileTypes;
  final List<String>? directories;
  final int? maxResults;

  const SearchFilesParams({
    required this.query,
    this.fileTypes,
    this.directories,
    this.maxResults,
  });
}

class SearchFilesUseCase
    implements UseCase<List<FileSearchResult>, SearchFilesParams> {
  final FileSearchRepository repository;

  SearchFilesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FileSearchResult>>> call(
    SearchFilesParams params,
  ) async {
    // Validate query
    if (params.query.trim().isEmpty) {
      return const Left(
          ValidationFailure(message: 'Search query cannot be empty'));
    }

    // Validate max results
    if (params.maxResults != null && params.maxResults! < 1) {
      return const Left(
          ValidationFailure(message: 'Max results must be greater than 0'));
    }

    return await repository.searchFiles(
      query: params.query.trim(),
      fileTypes: params.fileTypes,
      directories: params.directories,
      maxResults: params.maxResults,
    );
  }
}
