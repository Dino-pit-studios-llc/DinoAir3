import 'package:dartz/dartz.dart';
import '../../domain/entities/file_search_result.dart';
import '../../domain/entities/directory_config.dart';
import '../../domain/entities/search_statistics.dart';
import '../../domain/repositories/file_search_repository.dart';
import '../datasources/file_search_remote_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failure.dart';

/// Implementation of [FileSearchRepository] that uses remote data sources.
///
/// This repository handles:
/// - Converting between domain entities and DTOs
/// - Error handling and conversion from exceptions to failures
/// - Coordinating calls to remote data sources
class FileSearchRepositoryImpl implements FileSearchRepository {
  final FileSearchRemoteDataSource remoteDataSource;

  FileSearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FileSearchResult>>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  }) async {
    try {
      final results = await remoteDataSource.searchFiles(
        query: query,
        fileTypes: fileTypes,
        directories: directories,
        maxResults: maxResults,
      );
      return Right(results.map((dto) => dto.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, FileSearchResult>> getFileInfo({
    required String filePath,
  }) async {
    try {
      final result = await remoteDataSource.getFileInfo(filePath);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addToIndex({
    required String path,
    bool includeSubdirectories = true,
  }) async {
    try {
      await remoteDataSource.addToIndex(path, includeSubdirectories);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromIndex({
    required String path,
  }) async {
    try {
      await remoteDataSource.removeFromIndex(path);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SearchStatistics>> getSearchStatistics() async {
    try {
      final stats = await remoteDataSource.getSearchStatistics();
      return Right(stats.toEntity());
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DirectoryConfig>>> getWatchedDirectories() async {
    try {
      final directories = await remoteDataSource.getWatchedDirectories();
      return Right(directories.map((dto) => dto.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addWatchedDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  }) async {
    try {
      await remoteDataSource.addWatchedDirectory(
        path,
        includeSubdirectories,
        fileExtensions,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeWatchedDirectory({
    required String path,
  }) async {
    try {
      await remoteDataSource.removeWatchedDirectory(path);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reindexAll() async {
    try {
      await remoteDataSource.reindexAll();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ApiFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: 'Unexpected error: $e'));
    }
  }
}
