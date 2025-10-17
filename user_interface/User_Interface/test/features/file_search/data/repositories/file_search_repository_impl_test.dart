import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_dash/features/file_search/data/datasources/file_search_remote_data_source.dart';
import 'package:crypto_dash/features/file_search/data/models/directory_config_dto.dart';
import 'package:crypto_dash/features/file_search/data/models/file_search_result_dto.dart';
import 'package:crypto_dash/features/file_search/data/models/search_statistics_dto.dart';
import 'package:crypto_dash/features/file_search/data/repositories/file_search_repository_impl.dart';
import 'package:crypto_dash/features/file_search/domain/entities/directory_config.dart';
import 'package:crypto_dash/features/file_search/domain/entities/file_search_result.dart';
import 'package:crypto_dash/features/file_search/domain/entities/search_statistics.dart';
import 'package:crypto_dash/core/errors/exceptions.dart';
import 'package:crypto_dash/core/errors/failure.dart';

// Generate mock class
@GenerateMocks([FileSearchRemoteDataSource])
import 'file_search_repository_impl_test.mocks.dart';

void main() {
  late MockFileSearchRemoteDataSource mockDataSource;
  late FileSearchRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockFileSearchRemoteDataSource();
    repository = FileSearchRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('FileSearchRepositoryImpl', () {
    group('searchFiles', () {
      test('should return mapped results on successful search', () async {
        // Arrange
        const query = 'test query';
        final dtos = [
          const FileSearchResultDTO(
            filePath: '/test/file1.txt',
            fileName: 'file1.txt',
            fileType: 'txt',
            fileSize: 1024,
            lastModified: '2024-01-01T00:00:00Z',
            relevanceScore: 0.95,
            matchedKeywords: ['test'],
          ),
        ];

        when(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).thenAnswer((_) async => dtos);

        // Act
        final result = await repository.searchFiles(query: query);

        // Assert
        expect(result, isA<Right<Failure, List<FileSearchResult>>>());
        final results = (result as Right).value;
        expect(results, hasLength(1));
        expect(results.first.filePath, '/test/file1.txt');
        expect(results.first.fileName, 'file1.txt');
        verify(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const query = 'test query';
        const exception = ServerException(
          message: 'Server error',
          statusCode: 500,
        );

        when(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).thenThrow(exception);

        // Act
        final result = await repository.searchFiles(query: query);

        // Assert
        expect(result, isA<Left<Failure, List<FileSearchResult>>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Server error');
        expect(failure.statusCode, 500);
        verify(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).called(1);
      });

      test('should return UnknownFailure on unexpected error', () async {
        // Arrange
        const query = 'test query';

        when(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.searchFiles(query: query);

        // Assert
        expect(result, isA<Left<Failure, List<FileSearchResult>>>());
        final failure = (result as Left).value as UnknownFailure;
        expect(failure.message, 'Unexpected error: Exception: Unexpected error');
        verify(mockDataSource.searchFiles(
          query: query,
          fileTypes: null,
          directories: null,
          maxResults: null,
        )).called(1);
      });
    });

    group('getFileInfo', () {
      test('should return mapped result on successful getFileInfo', () async {
        // Arrange
        const filePath = '/test/file.txt';
        const dto = FileSearchResultDTO(
          filePath: filePath,
          fileName: 'file.txt',
          fileType: 'txt',
          fileSize: 2048,
          lastModified: '2024-01-01T00:00:00Z',
          relevanceScore: 1.0,
          matchedKeywords: ['test'],
        );

        when(mockDataSource.getFileInfo(filePath))
            .thenAnswer((_) async => dto);

        // Act
        final result = await repository.getFileInfo(filePath: filePath);

        // Assert
        expect(result, isA<Right<Failure, FileSearchResult>>());
        final fileInfo = (result as Right).value;
        expect(fileInfo.filePath, filePath);
        expect(fileInfo.fileName, 'file.txt');
        verify(mockDataSource.getFileInfo(filePath)).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const filePath = '/test/file.txt';
        const exception = ServerException(
          message: 'File not found',
          statusCode: 404,
        );

        when(mockDataSource.getFileInfo(filePath)).thenThrow(exception);

        // Act
        final result = await repository.getFileInfo(filePath: filePath);

        // Assert
        expect(result, isA<Left<Failure, FileSearchResult>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'File not found');
        expect(failure.statusCode, 404);
        verify(mockDataSource.getFileInfo(filePath)).called(1);
      });
    });

    group('addToIndex', () {
      test('should return Right on successful addToIndex', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;

        when(mockDataSource.addToIndex(path, includeSubdirectories))
            .thenAnswer((_) async => ());

        // Act
        final result = await repository.addToIndex(
          path: path,
          includeSubdirectories: includeSubdirectories,
        );

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockDataSource.addToIndex(path, includeSubdirectories)).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;
        const exception = ServerException(
          message: 'Index failed',
          statusCode: 500,
        );

        when(mockDataSource.addToIndex(path, includeSubdirectories))
            .thenThrow(exception);

        // Act
        final result = await repository.addToIndex(
          path: path,
          includeSubdirectories: includeSubdirectories,
        );

        // Assert
        expect(result, isA<Left<Failure, void>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Index failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.addToIndex(path, includeSubdirectories)).called(1);
      });
    });

    group('removeFromIndex', () {
      test('should return Right on successful removeFromIndex', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDataSource.removeFromIndex(path))
            .thenAnswer((_) async => ());

        // Act
        final result = await repository.removeFromIndex(path: path);

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockDataSource.removeFromIndex(path)).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const path = '/test/directory';
        const exception = ServerException(
          message: 'Remove failed',
          statusCode: 500,
        );

        when(mockDataSource.removeFromIndex(path)).thenThrow(exception);

        // Act
        final result = await repository.removeFromIndex(path: path);

        // Assert
        expect(result, isA<Left<Failure, void>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Remove failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.removeFromIndex(path)).called(1);
      });
    });

    group('getSearchStatistics', () {
      test('should return mapped statistics on successful call', () async {
        // Arrange
        const dto = SearchStatisticsDTO(
          totalFiles: 1000,
          indexedFiles: 800,
          totalDirectories: 50,
          lastIndexTime: '2024-01-01T00:00:00Z',
          fileTypeDistribution: {'txt': 500, 'md': 300},
        );

        when(mockDataSource.getSearchStatistics())
            .thenAnswer((_) async => dto);

        // Act
        final result = await repository.getSearchStatistics();

        // Assert
        expect(result, isA<Right<Failure, SearchStatistics>>());
        final stats = (result as Right).value;
        expect(stats.totalFiles, 1000);
        expect(stats.indexedFiles, 800);
        expect(stats.totalDirectories, 50);
        verify(mockDataSource.getSearchStatistics()).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const exception = ServerException(
          message: 'Stats failed',
          statusCode: 500,
        );

        when(mockDataSource.getSearchStatistics()).thenThrow(exception);

        // Act
        final result = await repository.getSearchStatistics();

        // Assert
        expect(result, isA<Left<Failure, SearchStatistics>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Stats failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.getSearchStatistics()).called(1);
      });
    });

    group('getWatchedDirectories', () {
      test('should return mapped directories on successful call', () async {
        // Arrange
        final dtos = [
          const DirectoryConfigDTO(
            path: '/test/dir1',
            isWatched: true,
            includeSubdirectories: true,
            fileExtensions: ['txt', 'md'],
          ),
        ];

        when(mockDataSource.getWatchedDirectories())
            .thenAnswer((_) async => dtos);

        // Act
        final result = await repository.getWatchedDirectories();

        // Assert
        expect(result, isA<Right<Failure, List<DirectoryConfig>>>());
        final directories = (result as Right).value;
        expect(directories, hasLength(1));
        expect(directories.first.path, '/test/dir1');
        expect(directories.first.isWatched, true);
        verify(mockDataSource.getWatchedDirectories()).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const exception = ServerException(
          message: 'Directories failed',
          statusCode: 500,
        );

        when(mockDataSource.getWatchedDirectories()).thenThrow(exception);

        // Act
        final result = await repository.getWatchedDirectories();

        // Assert
        expect(result, isA<Left<Failure, List<DirectoryConfig>>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Directories failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.getWatchedDirectories()).called(1);
      });
    });

    group('addWatchedDirectory', () {
      test('should return Right on successful addWatchedDirectory', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;
        const fileExtensions = ['txt', 'md'];

        when(mockDataSource.addWatchedDirectory(
          path,
          includeSubdirectories,
          fileExtensions,
        )).thenAnswer((_) async => ());

        // Act
        final result = await repository.addWatchedDirectory(
          path: path,
          includeSubdirectories: includeSubdirectories,
          fileExtensions: fileExtensions,
        );

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockDataSource.addWatchedDirectory(
          path,
          includeSubdirectories,
          fileExtensions,
        )).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;
        const fileExtensions = ['txt', 'md'];
        const exception = ServerException(
          message: 'Add directory failed',
          statusCode: 500,
        );

        when(mockDataSource.addWatchedDirectory(
          path,
          includeSubdirectories,
          fileExtensions,
        )).thenThrow(exception);

        // Act
        final result = await repository.addWatchedDirectory(
          path: path,
          includeSubdirectories: includeSubdirectories,
          fileExtensions: fileExtensions,
        );

        // Assert
        expect(result, isA<Left<Failure, void>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Add directory failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.addWatchedDirectory(
          path,
          includeSubdirectories,
          fileExtensions,
        )).called(1);
      });
    });

    group('removeWatchedDirectory', () {
      test('should return Right on successful removeWatchedDirectory', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDataSource.removeWatchedDirectory(path))
            .thenAnswer((_) async => ());

        // Act
        final result = await repository.removeWatchedDirectory(path: path);

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockDataSource.removeWatchedDirectory(path)).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const path = '/test/directory';
        const exception = ServerException(
          message: 'Remove directory failed',
          statusCode: 500,
        );

        when(mockDataSource.removeWatchedDirectory(path)).thenThrow(exception);

        // Act
        final result = await repository.removeWatchedDirectory(path: path);

        // Assert
        expect(result, isA<Left<Failure, void>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Remove directory failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.removeWatchedDirectory(path)).called(1);
      });
    });

    group('reindexAll', () {
      test('should return Right on successful reindexAll', () async {
        // Arrange
        when(mockDataSource.reindexAll()).thenAnswer((_) async => ());

        // Act
        final result = await repository.reindexAll();

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockDataSource.reindexAll()).called(1);
      });

      test('should return ApiFailure on ServerException', () async {
        // Arrange
        const exception = ServerException(
          message: 'Reindex failed',
          statusCode: 500,
        );

        when(mockDataSource.reindexAll()).thenThrow(exception);

        // Act
        final result = await repository.reindexAll();

        // Assert
        expect(result, isA<Left<Failure, void>>());
        final failure = (result as Left).value as ApiFailure;
        expect(failure.message, 'Reindex failed');
        expect(failure.statusCode, 500);
        verify(mockDataSource.reindexAll()).called(1);
      });
    });
  });
}
