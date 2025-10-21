import 'package:dio/dio.dart';
import '../models/file_search_result_dto.dart';
import '../models/directory_config_dto.dart';
import '../models/search_statistics_dto.dart';
import '../../../../core/errors/exceptions.dart';

/// Abstract interface for file search remote data source operations.
///
/// Defines all network operations related to file search, including:
/// - File searching and information retrieval
/// - Index management (adding/removing files and directories)
/// - Directory watching management
/// - Search statistics retrieval
/// - Reindexing operations
abstract class FileSearchRemoteDataSource {
  /// Search files by query with optional filters.
  ///
  /// Throws [ServerException] if the request fails.
  Future<List<FileSearchResultDTO>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  });

  /// Get detailed information about a specific file.
  ///
  /// Throws [ServerException] if the request fails.
  Future<FileSearchResultDTO> getFileInfo(String filePath);

  /// Add a file or directory to the search index.
  ///
  /// Throws [ServerException] if the request fails.
  Future<void> addToIndex(String path, bool includeSubdirectories);

  /// Remove a file or directory from the search index.
  ///
  /// Throws [ServerException] if the request fails.
  Future<void> removeFromIndex(String path);

  /// Get current search statistics.
  ///
  /// Throws [ServerException] if the request fails.
  Future<SearchStatisticsDTO> getSearchStatistics();

  /// Get list of watched directories.
  ///
  /// Throws [ServerException] if the request fails.
  Future<List<DirectoryConfigDTO>> getWatchedDirectories();

  /// Add a directory to watch list.
  ///
  /// Throws [ServerException] if the request fails.
  Future<void> addWatchedDirectory(
    String path,
    bool includeSubdirectories,
    List<String>? extensions,
  );

  /// Remove a directory from watch list.
  ///
  /// Throws [ServerException] if the request fails.
  Future<void> removeWatchedDirectory(String path);

  /// Trigger a reindex of all watched directories.
  ///
  /// Throws [ServerException] if the request fails.
  Future<void> reindexAll();
}

/// Implementation of [FileSearchRemoteDataSource] using Dio HTTP client.
///
/// Handles all network communication for file search operations and
/// converts API responses to DTOs.
class FileSearchRemoteDataSourceImpl implements FileSearchRemoteDataSource {
  final Dio client;
  final String baseUrl;

  FileSearchRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<List<FileSearchResultDTO>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  }) async {
    try {
      final response = await client.post(
        '$baseUrl/search',
        data: {
          'query': query,
          if (fileTypes != null) 'file_types': fileTypes,
          if (directories != null) 'directories': directories,
          if (maxResults != null) 'max_results': maxResults,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'] ?? [];
        return results
            .map((json) =>
                FileSearchResultDTO.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to search files',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<FileSearchResultDTO> getFileInfo(String filePath) async {
    try {
      final response = await client.get(
        '$baseUrl/info',
        queryParameters: {'file_path': filePath},
      );

      if (response.statusCode == 200) {
        return FileSearchResultDTO.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get file info',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> addToIndex(String path, bool includeSubdirectories) async {
    try {
      final response = await client.post(
        '$baseUrl/index',
        data: {
          'path': path,
          'include_subdirectories': includeSubdirectories,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to add to index',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> removeFromIndex(String path) async {
    try {
      final response = await client.delete(
        '$baseUrl/index',
        queryParameters: {'path': path},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to remove from index',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SearchStatisticsDTO> getSearchStatistics() async {
    try {
      final response = await client.get('$baseUrl/stats');

      if (response.statusCode == 200) {
        return SearchStatisticsDTO.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get search statistics',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<DirectoryConfigDTO>> getWatchedDirectories() async {
    try {
      final response = await client.get('$baseUrl/directories');

      if (response.statusCode == 200) {
        final List<dynamic> directories = response.data['directories'] ?? [];
        return directories
            .map((json) =>
                DirectoryConfigDTO.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get watched directories',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> addWatchedDirectory(
    String path,
    bool includeSubdirectories,
    List<String>? extensions,
  ) async {
    try {
      final response = await client.post(
        '$baseUrl/directories',
        data: {
          'path': path,
          'include_subdirectories': includeSubdirectories,
          if (extensions != null) 'file_extensions': extensions,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to add watched directory',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> removeWatchedDirectory(String path) async {
    try {
      final response = await client.delete(
        '$baseUrl/directories',
        queryParameters: {'path': path},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to remove watched directory',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> reindexAll() async {
    try {
      final response = await client.post('$baseUrl/reindex');

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw ServerException(
          message: 'Failed to trigger reindex',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
