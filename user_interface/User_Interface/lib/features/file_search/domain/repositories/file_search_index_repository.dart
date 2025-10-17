import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/search_statistics.dart';

/// Repository interface for file search indexing operations
abstract class FileSearchIndexRepository {
  /// Add a file or directory to the search index.
  ///
  /// [path] Path to file or directory to index.
  /// [includeSubdirectories] Whether to recursively index subdirectories.
  ///
  /// Returns Either<Failure, void>.
  Future<Either<Failure, void>> addToIndex({
    required String path,
    bool includeSubdirectories = true,
  });

  /// Remove a file or directory from the search index.
  ///
  /// [path] Path to file or directory to remove.
  ///
  /// Returns Either<Failure, void>.
  Future<Either<Failure, void>> removeFromIndex({
    required String path,
  });

  /// Get current search statistics.
  ///
  /// Returns Either<Failure, SearchStatistics>.
  Future<Either<Failure, SearchStatistics>> getSearchStatistics();

  /// Trigger a reindex of all watched directories.
  ///
  /// Returns Either<Failure, void>.
  Future<Either<Failure, void>> reindexAll();
}
