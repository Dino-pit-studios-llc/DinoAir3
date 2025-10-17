import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../services/api/api_providers.dart';
import '../../data/datasources/file_search_remote_data_source.dart';
import '../../data/repositories/file_search_repository_impl.dart';
import '../../domain/entities/file_search_result.dart';
import '../../domain/entities/directory_config.dart';
import '../../domain/entities/search_statistics.dart';
import '../../domain/repositories/file_search_repository.dart';
import '../../domain/usecases/search_files_use_case.dart';
import '../../domain/usecases/get_file_info_use_case.dart';
import '../../domain/usecases/add_to_index_use_case.dart';
import '../../domain/usecases/remove_from_index_use_case.dart';
import '../../domain/usecases/get_search_statistics_use_case.dart';
import '../../domain/usecases/get_watched_directories_use_case.dart';
import '../../domain/usecases/add_watched_directory_use_case.dart';
import '../../domain/usecases/remove_watched_directory_use_case.dart';
import '../../domain/usecases/reindex_all_use_case.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Provider for the file search repository
final fileSearchRepositoryProvider = Provider<FileSearchRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final dataSource = FileSearchRemoteDataSourceImpl(
    client: dio,
    baseUrl: '/api/v1/file_search',
  );
  return FileSearchRepositoryImpl(remoteDataSource: dataSource);
});

// ============================================================================
// Use Case Providers
// ============================================================================

/// Provider for search files use case
final searchFilesUseCaseProvider = Provider<SearchFilesUseCase>((ref) {
  return SearchFilesUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for get file info use case
final getFileInfoUseCaseProvider = Provider<GetFileInfoUseCase>((ref) {
  return GetFileInfoUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for add to index use case
final addToIndexUseCaseProvider = Provider<AddToIndexUseCase>((ref) {
  return AddToIndexUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for remove from index use case
final removeFromIndexUseCaseProvider = Provider<RemoveFromIndexUseCase>((ref) {
  return RemoveFromIndexUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for get search statistics use case
final getSearchStatisticsUseCaseProvider =
    Provider<GetSearchStatisticsUseCase>((ref) {
  return GetSearchStatisticsUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for get watched directories use case
final getWatchedDirectoriesUseCaseProvider =
    Provider<GetWatchedDirectoriesUseCase>((ref) {
  return GetWatchedDirectoriesUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for add watched directory use case
final addWatchedDirectoryUseCaseProvider =
    Provider<AddWatchedDirectoryUseCase>((ref) {
  return AddWatchedDirectoryUseCase(ref.watch(fileSearchRepositoryProvider));
});

/// Provider for remove watched directory use case
final removeWatchedDirectoryUseCaseProvider =
    Provider<RemoveWatchedDirectoryUseCase>((ref) {
  return RemoveWatchedDirectoryUseCase(
      ref.watch(fileSearchRepositoryProvider));
});

/// Provider for reindex all use case
final reindexAllUseCaseProvider = Provider<ReindexAllUseCase>((ref) {
  return ReindexAllUseCase(ref.watch(fileSearchRepositoryProvider));
});

// ============================================================================
// Search State Notifier
// ============================================================================

/// State notifier for file search results
class FileSearchNotifier extends AsyncNotifier<List<FileSearchResult>> {
  String _query = '';
  List<String> _fileTypes = [];
  List<String> _directories = [];
  int _maxResults = 100;

  @override
  Future<List<FileSearchResult>> build() async {
    // Start with empty results until user performs a search
    return [];
  }

  /// Search files with the given parameters
  Future<void> search({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  }) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    _query = query.trim();
    _fileTypes = fileTypes ?? [];
    _directories = directories ?? [];
    _maxResults = maxResults ?? 100;

    state = const AsyncValue.loading();

    final useCase = ref.read(searchFilesUseCaseProvider);
    final result = await useCase(
      SearchFilesParams(
        query: _query,
        fileTypes: _fileTypes.isEmpty ? null : _fileTypes,
        directories: _directories.isEmpty ? null : _directories,
        maxResults: _maxResults,
      ),
    );

    state = result.fold(
      (failure) {
        // Try to provide a more specific error message
        String errorMsg;
        if (failure.message != null && failure.message!.isNotEmpty) {
          errorMsg = failure.message!;
        } else if (failure is Exception) {
          errorMsg = 'Search failed: ${failure.toString()}';
        } else {
          errorMsg = 'Search failed due to an unknown error.';
        }
        return AsyncValue.error(errorMsg, StackTrace.current);
      },
      (results) => AsyncValue.data(results),
    );
  }

  /// Clear search results
  void clear() {
    _query = '';
    _fileTypes = [];
    _directories = [];
    state = const AsyncValue.data([]);
  }

  /// Refresh current search
  Future<void> refresh() async {
    if (_query.isNotEmpty) {
      await search(
        query: _query,
        fileTypes: _fileTypes,
        directories: _directories,
        maxResults: _maxResults,
      );
    }
  }

  /// Get current search query
  String get currentQuery => _query;

  /// Check if a search is active
  bool get hasActiveSearch => _query.isNotEmpty;
}

/// Provider for file search results
final fileSearchProvider =
    AsyncNotifierProvider<FileSearchNotifier, List<FileSearchResult>>(
  () => FileSearchNotifier(),
);

// ============================================================================
// Search UI State Providers
// ============================================================================

/// Provider for search query input (for UI binding)
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for selected file types filter
final selectedFileTypesProvider = StateProvider<List<String>>((ref) => []);

/// Provider for selected directories filter
final selectedDirectoriesProvider = StateProvider<List<String>>((ref) => []);

/// Provider for max results setting
final maxResultsProvider = StateProvider<int>((ref) => 100);

// ============================================================================
// Search Statistics Provider
// ============================================================================

/// State notifier for search statistics
class SearchStatisticsNotifier extends AsyncNotifier<SearchStatistics> {
  @override
  Future<SearchStatistics> build() async {
    return _fetchStatistics();
  }

  Future<SearchStatistics> _fetchStatistics() async {
    final useCase = ref.read(getSearchStatisticsUseCaseProvider);
    final result = await useCase(const NoParams());

    return result.fold(
      (failure) => throw Exception(failure.message ?? 'Failed to load statistics'),
      (stats) => stats,
    );
  }

  /// Refresh statistics
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStatistics());
  }
}

/// Provider for search statistics
final searchStatisticsProvider =
    AsyncNotifierProvider<SearchStatisticsNotifier, SearchStatistics>(
  () => SearchStatisticsNotifier(),
);

// ============================================================================
// Watched Directories Provider
// ============================================================================

/// State notifier for watched directories
class WatchedDirectoriesNotifier
    extends AsyncNotifier<List<DirectoryConfig>> {
  @override
  Future<List<DirectoryConfig>> build() async {
    return _fetchDirectories();
  }

  Future<List<DirectoryConfig>> _fetchDirectories() async {
    final useCase = ref.read(getWatchedDirectoriesUseCaseProvider);
    final result = await useCase(const NoParams());

    return result.fold(
      (failure) => throw Exception(failure.message ?? 'Failed to load directories'),
      (directories) => directories,
    );
  }

  /// Add a directory to the watch list
  Future<void> addDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  }) async {
    final useCase = ref.read(addWatchedDirectoryUseCaseProvider);
    final result = await useCase(
      AddWatchedDirectoryParams(
        path: path,
        includeSubdirectories: includeSubdirectories,
        fileExtensions: fileExtensions,
      ),
    );

    await result.fold(
      (failure) async {
        throw Exception(failure.message ?? 'Failed to add directory');
      },
      (_) async {
        // Refresh the list after successful addition
        await refresh();
      },
    );
  }

  /// Remove a directory from the watch list
  Future<void> removeDirectory(String path) async {
    final useCase = ref.read(removeWatchedDirectoryUseCaseProvider);
    final result = await useCase(RemoveWatchedDirectoryParams(path: path));

    await result.fold(
      (failure) async {
        throw Exception(failure.message ?? 'Failed to remove directory');
      },
      (_) async {
        // Refresh the list after successful removal
        await refresh();
      },
    );
  }

  /// Refresh watched directories list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDirectories());
  }

  /// Trigger reindex of all directories
  Future<void> reindexAll() async {
    final useCase = ref.read(reindexAllUseCaseProvider);
    final result = await useCase(const NoParams());

    await result.fold(
      (failure) async {
        throw Exception(failure.message ?? 'Failed to trigger reindex');
      },
      (_) async {
        // Refresh after successful reindex trigger
        await refresh();
        // Also refresh statistics
        ref.read(searchStatisticsProvider.notifier).refresh();
      },
    );
  }
}

/// Provider for watched directories
final watchedDirectoriesProvider =
    AsyncNotifierProvider<WatchedDirectoriesNotifier, List<DirectoryConfig>>(
  () => WatchedDirectoriesNotifier(),
);

// ============================================================================
// Computed Providers
// ============================================================================

/// Provider for search results count
final searchResultsCountProvider = Provider<int>((ref) {
  final searchAsync = ref.watch(fileSearchProvider);
  return searchAsync.maybeWhen(
    data: (results) => results.length,
    orElse: () => 0,
  );
});

/// Provider for watched directories count
final watchedDirectoriesCountProvider = Provider<int>((ref) {
  final directoriesAsync = ref.watch(watchedDirectoriesProvider);
  return directoriesAsync.maybeWhen(
    data: (directories) => directories.length,
    orElse: () => 0,
  );
});

/// Provider for indexed files count
final indexedFilesCountProvider = Provider<int>((ref) {
  final statsAsync = ref.watch(searchStatisticsProvider);
  return statsAsync.maybeWhen(
    data: (stats) => stats.indexedFiles,
    orElse: () => 0,
  );
});
