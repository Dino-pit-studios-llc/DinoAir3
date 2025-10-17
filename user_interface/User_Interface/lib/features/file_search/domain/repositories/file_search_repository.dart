import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/file_search_result.dart';
import '../entities/directory_config.dart';
import '../entities/search_statistics.dart';

/// Repository interface for file search domain operations.
///
/// This repository consolidates responsibilities including:
/// - Search operations (searching files and retrieving file info)
/// - Index management (adding, removing, and reindexing indexed paths)
/// - Directory watching (managing watched directories for search)
/// - Search statistics retrieval
abstract class FileSearchRepository {
  /// Search files by query with optional filters.
  ///
  /// Returns a list of matching files sorted by relevance score.
  Future<Either<Failure, List<FileSearchResult>>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  });

  /// Get detailed information about a specific file.
  ///
  /// Returns file metadata including size, modification date, and content.
  Future<Either<Failure, FileSearchResult>> getFileInfo({
    required String filePath,
  });

  /// Adds a directory or file path to the search index.
  ///
  /// [path] is the directory or file path to be indexed.
  /// [includeSubdirectories] determines whether subdirectories should also be indexed (default: true).
  ///
  /// Returns [Either] containing [Failure] on error or [void] on success.
  Future<Either<Failure, void>> addToIndex({
    required String path,
    bool includeSubdirectories = true,
  });

  /// Removes a directory or file path from the search index.
  ///
  /// [path] is the directory or file path to be removed from the index.
  ///
  /// Returns [Either] containing [Failure] on error or [void] on success.
  Future<Either<Failure, void>> removeFromIndex({
    required String path,
  });

  /// Retrieves search statistics such as number of indexed files and directories.
  ///
  /// Returns [Either] containing [Failure] on error or [SearchStatistics] on success.
  Future<Either<Failure, SearchStatistics>> getSearchStatistics();

  /// Get list of all watched directories.
  ///
  /// Returns directory configurations including paths, extensions, and indexing status.
  Future<Either<Failure, List<DirectoryConfig>>> getWatchedDirectories();

  /// Adds a directory to the list of watched directories for search.
  ///
  /// [path] is the directory path to watch.
  /// [includeSubdirectories] determines whether subdirectories should also be watched (default: true).
  /// [fileExtensions] is an optional list of file extensions to filter watched files.
  ///
  /// Returns [Either] containing [Failure] on error or [void] on success.
  Future<Either<Failure, void>> addWatchedDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  });

  /// Removes a directory from the list of watched directories.
  ///
  /// [path] is the directory path to stop watching.
  ///
  /// Returns [Either] containing [Failure] on error or [void] on success.
  Future<Either<Failure, void>> removeWatchedDirectory({
    required String path,
  });

  /// Triggers a reindexing operation for all currently indexed files and directories.
  ///
  /// Returns a [Future] containing an [Either] with a [Failure] if the operation fails,
  /// or [void] if the reindexing completes successfully.
  Future<Either<Failure, void>> reindexAll();
}
