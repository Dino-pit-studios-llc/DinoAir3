# Phase 4: File Search Feature - Detailed Implementation Plan

**Status:** 🔴 Not Started
**Priority:** Medium
**Dependencies:** Phase 1 (Backend Integration Layer)
**Estimated Duration:** 1 week
**Target Completion:** TBD

---

## Overview

The File Search feature provides users with the ability to search through indexed files using keywords, manage watched directories, and preview/open files directly from the Flutter UI. This feature integrates with the existing backend file search API that supports keyword search, directory management, and file indexing.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Search Screen│  │ Results List │  │ Dir Mgmt UI  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│           ▲                 ▲                 ▲          │
│           │                 │                 │          │
│           └─────────────────┴─────────────────┘          │
│                          │                                │
│                    Providers                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │ file_search_provider.dart                         │   │
│  │ directory_manager_provider.dart                   │   │
│  │ search_results_provider.dart                      │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Entities: FileSearchResult, DirectoryConfig       │   │
│  │ Repository: FileSearchRepository (abstract)       │   │
│  │ Use Cases:                                         │   │
│  │   - SearchFilesUseCase                            │   │
│  │   - GetFileInfoUseCase                            │   │
│  │   - AddDirectoryUseCase                           │   │
│  │   - RemoveDirectoryUseCase                        │   │
│  │   - GetSearchStatsUseCase                         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ DTOs: FileSearchResultDTO, DirectoryConfigDTO    │   │
│  │ Mappers: toEntity() / toDTO()                     │   │
│  │ Remote Data Source: FileSearchRemoteDataSource   │   │
│  │ Repository Impl: FileSearchRepositoryImpl        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                 Backend REST API
            /api/v1/file_search/*
```

---

## Phase 4.1: Domain Layer Implementation

### 4.1.1 Create File Search Result Entity

**File:** `lib/features/file_search/domain/entities/file_search_result.dart`

**Purpose:** Represent a single search result with file metadata.

**Implementation:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_search_result.freezed.dart';

@freezed
class FileSearchResult with _$FileSearchResult {
  const factory FileSearchResult({
    required String filePath,
    required String fileName,
    required String fileType,
    required int fileSize,
    required DateTime lastModified,
    required double relevanceScore,
    required List<String> matchedKeywords,
    String? fileContent,
    Map<String, dynamic>? metadata,
  }) = _FileSearchResult;

  const FileSearchResult._();

  // Computed properties
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
```

**Dependencies:**

- `freezed_annotation: ^2.4.1`
- Will need to run `flutter pub run build_runner build`

**Tasks:**

- [x] Define entity structure with all required fields
- [ ] Add computed properties for formatting
- [ ] Generate freezed code
- [ ] Add unit tests for computed properties

---

### 4.1.2 Create Directory Configuration Entity

**File:** `lib/features/file_search/domain/entities/directory_config.dart`

**Purpose:** Represent a watched directory configuration.

**Implementation:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'directory_config.freezed.dart';

@freezed
class DirectoryConfig with _$DirectoryConfig {
  const factory DirectoryConfig({
    required String path,
    required bool isWatched,
    required bool includeSubdirectories,
    required List<String> fileExtensions,
    DateTime? lastIndexed,
    int? indexedFileCount,
  }) = _DirectoryConfig;
}
```

**Tasks:**

- [ ] Define entity structure
- [ ] Generate freezed code
- [ ] Add validation logic for paths

---

### 4.1.3 Create Search Statistics Entity

**File:** `lib/features/file_search/domain/entities/search_statistics.dart`

**Implementation:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_statistics.freezed.dart';

@freezed
class SearchStatistics with _$SearchStatistics {
  const factory SearchStatistics({
    required int totalFiles,
    required int indexedFiles,
    required int totalDirectories,
    required DateTime lastIndexTime,
    required Map<String, int> fileTypeDistribution,
  }) = _SearchStatistics;
}
```

**Tasks:**

- [ ] Define entity structure
- [ ] Generate freezed code

---

### 4.1.4 Create File Search Repository Interface

**File:** `lib/features/file_search/domain/repositories/file_search_repository.dart`

**Purpose:** Define contract for file search operations.

**Implementation:**

```dart
import 'package:dartz/dartz.dart';
import '../entities/file_search_result.dart';
import '../entities/directory_config.dart';
import '../entities/search_statistics.dart';
import '../../../../core/errors/failures.dart';

abstract class FileSearchRepository {
  /// Search files by keywords
  /// Returns Either<Failure, List<FileSearchResult>>
  Future<Either<Failure, List<FileSearchResult>>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  });

  /// Get detailed information about a specific file
  Future<Either<Failure, FileSearchResult>> getFileInfo({
    required String filePath,
  });

  /// Add a file or directory to the search index
  Future<Either<Failure, void>> addToIndex({
    required String path,
    bool includeSubdirectories = true,
  });

  /// Remove a file or directory from the search index
  Future<Either<Failure, void>> removeFromIndex({
    required String path,
  });

  /// Get current search statistics
  Future<Either<Failure, SearchStatistics>> getSearchStatistics();

  /// Get list of watched directories
  Future<Either<Failure, List<DirectoryConfig>>> getWatchedDirectories();

  /// Add a directory to watch list
  Future<Either<Failure, void>> addWatchedDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  });

  /// Remove a directory from watch list
  Future<Either<Failure, void>> removeWatchedDirectory({
    required String path,
  });

  /// Trigger a reindex of all watched directories
  Future<Either<Failure, void>> reindexAll();
}
```

**Dependencies:**

- `dartz: ^0.10.1` (for Either monad)

**Tasks:**

- [ ] Define all repository methods
- [ ] Document each method with clear purpose
- [ ] Add parameter validation requirements

---

### 4.1.5 Create Use Cases

#### SearchFilesUseCase

**File:** `lib/features/file_search/domain/usecases/search_files_use_case.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/file_search_result.dart';
import '../repositories/file_search_repository.dart';
import '../../../../core/errors/failures.dart';
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

class SearchFilesUseCase implements UseCase<List<FileSearchResult>, SearchFilesParams> {
  final FileSearchRepository repository;

  SearchFilesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FileSearchResult>>> call(SearchFilesParams params) async {
    if (params.query.trim().isEmpty) {
      return Left(ValidationFailure('Search query cannot be empty'));
    }

    return await repository.searchFiles(
      query: params.query,
      fileTypes: params.fileTypes,
      directories: params.directories,
      maxResults: params.maxResults,
    );
  }
}
```

**Tasks:**

- [ ] Implement SearchFilesUseCase
- [ ] Implement GetFileInfoUseCase
- [ ] Implement AddDirectoryUseCase
- [ ] Implement RemoveDirectoryUseCase
- [ ] Implement GetSearchStatsUseCase
- [ ] Implement GetWatchedDirectoriesUseCase
- [ ] Implement ReindexAllUseCase
- [ ] Add unit tests for all use cases

---

## Phase 4.2: Data Layer Implementation

### 4.2.1 Create DTOs

#### FileSearchResultDTO

**File:** `lib/features/file_search/data/models/file_search_result_dto.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/file_search_result.dart';

part 'file_search_result_dto.freezed.dart';
part 'file_search_result_dto.g.dart';

@freezed
class FileSearchResultDTO with _$FileSearchResultDTO {
  const factory FileSearchResultDTO({
    @JsonKey(name: 'file_path') required String filePath,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_type') required String fileType,
    @JsonKey(name: 'file_size') required int fileSize,
    @JsonKey(name: 'last_modified') required String lastModified,
    @JsonKey(name: 'relevance_score') required double relevanceScore,
    @JsonKey(name: 'matched_keywords') required List<String> matchedKeywords,
    @JsonKey(name: 'file_content') String? fileContent,
    Map<String, dynamic>? metadata,
  }) = _FileSearchResultDTO;

  const FileSearchResultDTO._();

  factory FileSearchResultDTO.fromJson(Map<String, dynamic> json) =>
      _$FileSearchResultDTOFromJson(json);

  /// Convert DTO to domain entity
  FileSearchResult toEntity() {
    return FileSearchResult(
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      lastModified: DateTime.parse(lastModified),
      relevanceScore: relevanceScore,
      matchedKeywords: matchedKeywords,
      fileContent: fileContent,
      metadata: metadata,
    );
  }

  /// Convert domain entity to DTO
  factory FileSearchResultDTO.fromEntity(FileSearchResult entity) {
    return FileSearchResultDTO(
      filePath: entity.filePath,
      fileName: entity.fileName,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      lastModified: entity.lastModified.toIso8601String(),
      relevanceScore: entity.relevanceScore,
      matchedKeywords: entity.matchedKeywords,
      fileContent: entity.fileContent,
      metadata: entity.metadata,
    );
  }
}
```

**Tasks:**

- [ ] Implement FileSearchResultDTO
- [ ] Implement DirectoryConfigDTO
- [ ] Implement SearchStatisticsDTO
- [ ] Generate JSON serialization code
- [ ] Add mapper tests

---

### 4.2.2 Create Remote Data Source

**File:** `lib/features/file_search/data/datasources/file_search_remote_data_source.dart`

```dart
import 'package:dio/dio.dart';
import '../models/file_search_result_dto.dart';
import '../models/directory_config_dto.dart';
import '../models/search_statistics_dto.dart';
import '../../../../core/errors/exceptions.dart';

abstract class FileSearchRemoteDataSource {
  Future<List<FileSearchResultDTO>> searchFiles({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  });

  Future<FileSearchResultDTO> getFileInfo(String filePath);
  Future<void> addToIndex(String path, bool includeSubdirectories);
  Future<void> removeFromIndex(String path);
  Future<SearchStatisticsDTO> getSearchStatistics();
  Future<List<DirectoryConfigDTO>> getWatchedDirectories();
  Future<void> addWatchedDirectory(String path, bool includeSubdirectories, List<String>? extensions);
  Future<void> removeWatchedDirectory(String path);
  Future<void> reindexAll();
}

class FileSearchRemoteDataSourceImpl implements FileSearchRemoteDataSource {
  final Dio client;
  static const String baseUrl = '/api/v1/file_search';

  FileSearchRemoteDataSourceImpl({required this.client});

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
            .map((json) => FileSearchResultDTO.fromJson(json as Map<String, dynamic>))
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
            .map((json) => DirectoryConfigDTO.fromJson(json as Map<String, dynamic>))
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

      if (response.statusCode != 200 && response.statusCode != 202) {
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
```

**Tasks:**

- [ ] Implement all remote data source methods
- [ ] Add comprehensive error handling
- [ ] Add request/response logging
- [ ] Add timeout handling
- [ ] Write integration tests

---

### 4.2.3 Create Repository Implementation

**File:** `lib/features/file_search/data/repositories/file_search_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/file_search_result.dart';
import '../../domain/entities/directory_config.dart';
import '../../domain/entities/search_statistics.dart';
import '../../domain/repositories/file_search_repository.dart';
import '../datasources/file_search_remote_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SearchStatistics>> getSearchStatistics() async {
    try {
      final stats = await remoteDataSource.getSearchStatistics();
      return Right(stats.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DirectoryConfig>>> getWatchedDirectories() async {
    try {
      final directories = await remoteDataSource.getWatchedDirectories();
      return Right(directories.map((dto) => dto.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
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
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reindexAll() async {
    try {
      await remoteDataSource.reindexAll();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
```

**Tasks:**

- [ ] Implement repository with full error handling
- [ ] Add proper exception-to-failure mapping
- [ ] Write repository unit tests with mocked data source

---

## Phase 4.3: Presentation Layer Implementation

### 4.3.1 Create Providers

#### File Search Provider

**File:** `lib/features/file_search/presentation/providers/file_search_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_search_result.dart';
import '../../domain/usecases/search_files_use_case.dart';
import '../../data/repositories/file_search_repository_impl.dart';
import '../../data/datasources/file_search_remote_data_source.dart';
import '../../../../services/api/dio_client.dart';

// Repository provider
final fileSearchRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final remoteDataSource = FileSearchRemoteDataSourceImpl(
    client: dioClient.instance,
  );
  return FileSearchRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use case providers
final searchFilesUseCaseProvider = Provider((ref) {
  final repository = ref.watch(fileSearchRepositoryProvider);
  return SearchFilesUseCase(repository);
});

// Search results provider
final searchResultsProvider = StateNotifierProvider<SearchResultsNotifier, AsyncValue<List<FileSearchResult>>>((ref) {
  final useCase = ref.watch(searchFilesUseCaseProvider);
  return SearchResultsNotifier(useCase);
});

class SearchResultsNotifier extends StateNotifier<AsyncValue<List<FileSearchResult>>> {
  final SearchFilesUseCase searchFilesUseCase;

  SearchResultsNotifier(this.searchFilesUseCase) : super(const AsyncValue.data([]));

  Future<void> search({
    required String query,
    List<String>? fileTypes,
    List<String>? directories,
    int? maxResults,
  }) async {
    state = const AsyncValue.loading();

    final result = await searchFilesUseCase(SearchFilesParams(
      query: query,
      fileTypes: fileTypes,
      directories: directories,
      maxResults: maxResults,
    ));

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (results) => AsyncValue.data(results),
    );
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

// Search query provider (for UI state)
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected file types filter
final selectedFileTypesProvider = StateProvider<List<String>>((ref) => []);

// Selected directories filter
final selectedDirectoriesProvider = StateProvider<List<String>>((ref) => []);
```

#### Directory Manager Provider

**File:** `lib/features/file_search/presentation/providers/directory_manager_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/directory_config.dart';
import '../../domain/usecases/add_watched_directory_use_case.dart';
import '../../domain/usecases/remove_watched_directory_use_case.dart';
import '../../domain/usecases/get_watched_directories_use_case.dart';
import 'file_search_provider.dart';

// Use case providers
final getWatchedDirectoriesUseCaseProvider = Provider((ref) {
  final repository = ref.watch(fileSearchRepositoryProvider);
  return GetWatchedDirectoriesUseCase(repository);
});

final addWatchedDirectoryUseCaseProvider = Provider((ref) {
  final repository = ref.watch(fileSearchRepositoryProvider);
  return AddWatchedDirectoryUseCase(repository);
});

final removeWatchedDirectoryUseCaseProvider = Provider((ref) {
  final repository = ref.watch(fileSearchRepositoryProvider);
  return RemoveWatchedDirectoryUseCase(repository);
});

// Watched directories provider
final watchedDirectoriesProvider = StateNotifierProvider<WatchedDirectoriesNotifier, AsyncValue<List<DirectoryConfig>>>((ref) {
  final getUseCase = ref.watch(getWatchedDirectoriesUseCaseProvider);
  final addUseCase = ref.watch(addWatchedDirectoryUseCaseProvider);
  final removeUseCase = ref.watch(removeWatchedDirectoryUseCaseProvider);
  return WatchedDirectoriesNotifier(getUseCase, addUseCase, removeUseCase);
});

class WatchedDirectoriesNotifier extends StateNotifier<AsyncValue<List<DirectoryConfig>>> {
  final GetWatchedDirectoriesUseCase getWatchedDirectoriesUseCase;
  final AddWatchedDirectoryUseCase addWatchedDirectoryUseCase;
  final RemoveWatchedDirectoryUseCase removeWatchedDirectoryUseCase;

  WatchedDirectoriesNotifier(
    this.getWatchedDirectoriesUseCase,
    this.addWatchedDirectoryUseCase,
    this.removeWatchedDirectoryUseCase,
  ) : super(const AsyncValue.loading()) {
    loadDirectories();
  }

  Future<void> loadDirectories() async {
    state = const AsyncValue.loading();

    final result = await getWatchedDirectoriesUseCase(NoParams());

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (directories) => AsyncValue.data(directories),
    );
  }

  Future<void> addDirectory({
    required String path,
    bool includeSubdirectories = true,
    List<String>? fileExtensions,
  }) async {
    final result = await addWatchedDirectoryUseCase(AddWatchedDirectoryParams(
      path: path,
      includeSubdirectories: includeSubdirectories,
      fileExtensions: fileExtensions,
    ));

    result.fold(
      (failure) {
        // Handle error - could use a separate error state or show snackbar
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        // Reload directories after successful addition
        loadDirectories();
      },
    );
  }

  Future<void> removeDirectory(String path) async {
    final result = await removeWatchedDirectoryUseCase(RemoveWatchedDirectoryParams(path: path));

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        loadDirectories();
      },
    );
  }
}
```

**Tasks:**

- [ ] Implement all provider classes
- [ ] Add proper state management
- [ ] Add loading/error states
- [ ] Write provider tests

---

### 4.3.2 Create Search Screen

**File:** `lib/features/file_search/presentation/screens/file_search_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_search_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_filters_widget.dart';
import '../widgets/search_results_list_widget.dart';
import '../widgets/search_statistics_widget.dart';

class FileSearchScreen extends ConsumerStatefulWidget {
  const FileSearchScreen({super.key});

  @override
  ConsumerState<FileSearchScreen> createState() => _FileSearchScreenState();
}

class _FileSearchScreenState extends ConsumerState<FileSearchScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text;
    if (query.isEmpty) return;

    final fileTypes = ref.read(selectedFileTypesProvider);
    final directories = ref.read(selectedDirectoriesProvider);

    ref.read(searchResultsProvider.notifier).search(
      query: query,
      fileTypes: fileTypes.isEmpty ? null : fileTypes,
      directories: directories.isEmpty ? null : directories,
      maxResults: 100,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchResultsProvider.notifier).clear();
    ref.read(selectedFileTypesProvider.notifier).state = [];
    ref.read(selectedDirectoriesProvider.notifier).state = [];
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Search'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle filters',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to directory management screen
              Navigator.of(context).pushNamed('/file-search/directories');
            },
            tooltip: 'Manage directories',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              controller: _searchController,
              onSearch: _performSearch,
              onClear: _clearSearch,
            ),
          ),

          // Filters (collapsible)
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SearchFiltersWidget(
                onFilterChanged: _performSearch,
              ),
            ),

          // Statistics
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchStatisticsWidget(),
          ),

          const Divider(),

          // Results
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Enter a search query to find files'
                              : 'No results found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SearchResultsListWidget(results: results);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _performSearch,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Tasks:**

- [ ] Implement search screen UI
- [ ] Add search bar with auto-complete
- [ ] Add collapsible filter section
- [ ] Add results list with infinite scroll
- [ ] Add empty state and error handling
- [ ] Add loading indicators

---

### 4.3.3 Create Directory Management Screen

**File:** `lib/features/file_search/presentation/screens/directory_management_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/directory_manager_provider.dart';
import '../widgets/directory_card_widget.dart';

class DirectoryManagementScreen extends ConsumerWidget {
  const DirectoryManagementScreen({super.key});

  Future<void> _addDirectory(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      await ref.read(watchedDirectoriesProvider.notifier).addDirectory(
        path: result,
        includeSubdirectories: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory added successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoriesState = ref.watch(watchedDirectoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watched Directories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(watchedDirectoriesProvider.notifier).loadDirectories();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: directoriesState.when(
        data: (directories) {
          if (directories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No watched directories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add directories to start indexing files',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addDirectory(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Directory'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: directories.length,
            itemBuilder: (context, index) {
              final directory = directories[index];
              return DirectoryCardWidget(
                directory: directory,
                onRemove: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Directory'),
                      content: Text('Remove ${directory.path} from watched directories?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref
                        .read(watchedDirectoriesProvider.notifier)
                        .removeDirectory(directory.path);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Directory removed')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(watchedDirectoriesProvider.notifier).loadDirectories();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDirectory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Directory'),
      ),
    );
  }
}
```

**Dependencies:**

- `file_picker: ^6.0.0` (for directory selection dialog)

**Tasks:**

- [ ] Implement directory management UI
- [ ] Add directory picker integration
- [ ] Add confirmation dialogs
- [ ] Add directory card widgets
- [ ] Show indexing status per directory

---

### 4.3.4 Create Widgets

#### Search Result Card Widget

**File:** `lib/features/file_search/presentation/widgets/search_result_card_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/file_search_result.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchResultCardWidget extends StatelessWidget {
  final FileSearchResult result;

  const SearchResultCardWidget({
    required this.result,
    super.key,
  });

  Future<void> _openFile() async {
    final uri = Uri.file(result.filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: result.filePath));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Path copied to clipboard')),
    );
  }

  Color _getFileTypeColor(BuildContext context) {
    final ext = result.fileExtension.toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;

    if (['dart', 'py', 'js', 'ts', 'java', 'cpp', 'c', 'go'].contains(ext)) {
      return colorScheme.primary;
    } else if (['txt', 'md', 'doc', 'docx'].contains(ext)) {
      return colorScheme.secondary;
    } else if (['json', 'yaml', 'xml', 'config'].contains(ext)) {
      return colorScheme.tertiary;
    }
    return colorScheme.surfaceVariant;
  }

  IconData _getFileTypeIcon() {
    final ext = result.fileExtension.toLowerCase();

    if (['dart', 'py', 'js', 'ts', 'java', 'cpp', 'c', 'go'].contains(ext)) {
      return Icons.code;
    } else if (['txt', 'md', 'doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['json', 'yaml', 'xml', 'config'].contains(ext)) {
      return Icons.settings;
    } else if (['jpg', 'png', 'gif', 'svg'].contains(ext)) {
      return Icons.image;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _openFile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getFileTypeColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileTypeIcon(),
                      color: _getFileTypeColor(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.fileName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.filePath,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyPath(context),
                    tooltip: 'Copy path',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // File metadata
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetadataChip(
                    icon: Icons.folder,
                    label: result.fileType,
                  ),
                  _MetadataChip(
                    icon: Icons.storage,
                    label: result.fileSizeFormatted,
                  ),
                  _MetadataChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(result.lastModified),
                  ),
                  _MetadataChip(
                    icon: Icons.star,
                    label: '${(result.relevanceScore * 100).toStringAsFixed(0)}%',
                    color: Colors.amber,
                  ),
                ],
              ),

              // Matched keywords
              if (result.matchedKeywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: result.matchedKeywords
                      .map((keyword) => Chip(
                            label: Text(
                              keyword,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.surfaceVariant).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Dependencies:**

- `url_launcher: ^6.2.0` (for opening files)

**Tasks:**

- [ ] Implement SearchResultCardWidget
- [ ] Implement SearchBarWidget
- [ ] Implement SearchFiltersWidget
- [ ] Implement SearchResultsListWidget
- [ ] Implement SearchStatisticsWidget
- [ ] Implement DirectoryCardWidget
- [ ] Add file type icons and colors
- [ ] Add file preview capability

---

### 4.3.5 Add Routes

**File:** `lib/app/router.dart` (additions)

```dart
// Add to existing routes
GoRoute(
  path: '/file-search',
  name: 'file-search',
  builder: (context, state) => const FileSearchScreen(),
),
GoRoute(
  path: '/file-search/directories',
  name: 'file-search-directories',
  builder: (context, state) => const DirectoryManagementScreen(),
),
```

**Tasks:**

- [ ] Add file search routes to router
- [ ] Update drawer navigation to include file search
- [ ] Add deep linking support

---

## Testing Strategy

### Unit Tests

- [ ] Test all domain entities with freezed equality
- [ ] Test all use cases with mocked repositories
- [ ] Test all mappers (DTO ↔ Entity)
- [ ] Test repository implementation with mocked data sources
- [ ] Test error handling and edge cases

### Widget Tests

- [ ] Test SearchResultCardWidget with different file types
- [ ] Test SearchBarWidget input handling
- [ ] Test SearchFiltersWidget state management
- [ ] Test empty states and error states
- [ ] Test loading indicators

### Integration Tests

- [ ] Test full search flow (query → results → open file)
- [ ] Test directory management (add → list → remove)
- [ ] Test search with filters
- [ ] Test error recovery scenarios
- [ ] Test offline behavior

---

## Dependencies Required

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  dio: ^5.4.0

  # New for Phase 4
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  dartz: ^0.10.1 # For Either monad
  file_picker: ^6.0.0 # For directory selection
  url_launcher: ^6.2.0 # For opening files
  path: ^1.8.3 # For path manipulation

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  mockito: ^5.4.4
```

---

## Performance Considerations

1. **Search Debouncing:** Implement 300ms debounce on search input to avoid excessive API calls
2. **Pagination:** Implement pagination for large result sets (100 results per page)
3. **Result Caching:** Cache recent search results in memory with TTL
4. **Lazy Loading:** Use ListView.builder for efficient rendering of large lists
5. **Image Optimization:** Use cached_network_image for file thumbnails if implemented
6. **Index Management:** Provide background indexing status indicators

---

## Security Considerations

1. **Path Validation:** Validate all file paths before sending to backend
2. **File Access:** Respect system file permissions when opening files
3. **XSS Prevention:** Sanitize file content if displaying in UI
4. **Directory Permissions:** Check write permissions before allowing directory additions
5. **Rate Limiting:** Implement client-side rate limiting for search requests

---

## UX Enhancements

1. **Search Suggestions:** Add recent searches and autocomplete
2. **File Preview:** Add preview modal for supported file types
3. **Keyboard Shortcuts:** Add CMD/CTRL+K for quick search
4. **Search History:** Store and display recent searches
5. **Quick Filters:** Add one-click filters for common file types (code, docs, images)
6. **Sort Options:** Allow sorting by relevance, date, size, name
7. **Bulk Operations:** Add multi-select for batch operations

---

## Success Metrics

- [ ] Search returns results in < 2 seconds
- [ ] UI remains responsive during searches
- [ ] File opening works for all supported types
- [ ] Directory management is intuitive
- [ ] Error messages are clear and actionable
- [ ] 90%+ test coverage for domain layer
- [ ] Zero crashes during normal operation

---

## Timeline Breakdown

| Task                              | Duration     | Dependencies |
| --------------------------------- | ------------ | ------------ |
| Domain Layer (4.1)                | 1 day        | None         |
| Data Layer DTOs & Mappers (4.2.1) | 1 day        | 4.1          |
| Data Layer Remote Source (4.2.2)  | 1 day        | 4.2.1        |
| Data Layer Repository (4.2.3)     | 0.5 days     | 4.2.2        |
| Presentation Providers (4.3.1)    | 1 day        | 4.2.3        |
| Search Screen UI (4.3.2)          | 1 day        | 4.3.1        |
| Directory Management UI (4.3.3)   | 0.5 days     | 4.3.1        |
| Widgets (4.3.4)                   | 1 day        | 4.3.2        |
| Testing & Polish                  | 1 day        | All above    |
| **Total**                         | **7-8 days** |              |

---

## Next Steps

1. **Review Plan:** Get stakeholder approval on detailed implementation
2. **Create Tickets:** Break down tasks into Jira/GitHub issues
3. **Set Up Dependencies:** Update pubspec.yaml with all required packages
4. **Kickoff Sprint:** Begin with domain layer implementation
5. **Daily Standups:** Track progress and blockers

---

**Document Version:** 1.0
**Created:** 2025-10-10
**Author:** Development Team
**Status:** Ready for Implementation
