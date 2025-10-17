import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/directory_config.dart';

/// Repository interface for directory management operations
abstract class DirectoryManagementRepository {
  /// Get list of watched directories
  ///
  /// Returns Either<Failure, List<DirectoryConfig>>
  Future<Either<Failure, List<DirectoryConfig>>> getWatchedDirectories();

  /// Add a directory to watch list
  ///
  /// [path] - Directory path to watch
  /// [includeSubdirectories] - Whether to watch subdirectories
  /// [fileExtensions] - Optional list of file extensions to watch
  ///
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> addWatchedDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  });

  /// Remove a directory from watch list
  ///
  /// [path] - Directory path to remove
  ///
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> removeWatchedDirectory({
    required String path,
  });
}
