import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:crypto_dash/features/file_search/domain/entities/directory_config.dart';
import 'package:crypto_dash/features/file_search/domain/entities/file_search_result.dart';
import 'package:crypto_dash/features/file_search/domain/entities/search_statistics.dart';
import 'package:crypto_dash/features/file_search/domain/repositories/file_search_repository.dart';
import 'package:crypto_dash/core/errors/failure.dart';

// Generate mock class
@GenerateMocks([FileSearchRepository])
import 'file_search_repository_test.mocks.dart';

void main() {
  late MockFileSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockFileSearchRepository();
  });

  group('FileSearchRepository', () {
    test('should search files successfully', () async {
      // Arrange
      const query = 'test query';
      final expectedResults = [
        FileSearchResult(
          filePath: '/test/file1.txt',
          fileName: 'file1.txt',
          fileType: 'txt',
          fileSize: 1024,
          lastModified: DateTime.now(),
          relevanceScore: 0.95,
          matchedKeywords: ['test'],
        ),
      ];

      when(mockRepository.searchFiles(
        query: query,
        fileTypes: null,
        directories: null,
        maxResults: null,
      )).thenAnswer((_) async => Right(expectedResults));

      // Act
      final result = await mockRepository.searchFiles(query: query);

      // Assert
      expect(result, isA<Right<Failure, List<FileSearchResult>>>());
      expect((result as Right).value, expectedResults);
      verify(mockRepository.searchFiles(query: query)).called(1);
    });

    test('should handle search failure', () async {
      // Arrange
      const query = 'test query';
      const failure = ApiFailure(message: 'Search failed', statusCode: 500);

      when(mockRepository.searchFiles(
        query: query,
        fileTypes: null,
        directories: null,
        maxResults: null,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.searchFiles(query: query);

      // Assert
      expect(result, isA<Left<Failure, List<FileSearchResult>>>());
      expect((result as Left).value, failure);
      verify(mockRepository.searchFiles(query: query)).called(1);
    });

    test('should get file info successfully', () async {
      // Arrange
      const filePath = '/test/file.txt';
      final expectedResult = FileSearchResult(
        filePath: filePath,
        fileName: 'file.txt',
        fileType: 'txt',
        fileSize: 2048,
        lastModified: DateTime.now(),
        relevanceScore: 1.0,
        matchedKeywords: ['test'],
      );

      when(mockRepository.getFileInfo(filePath: filePath))
          .thenAnswer((_) async => Right(expectedResult));

      // Act
      final result = await mockRepository.getFileInfo(filePath: filePath);

      // Assert
      expect(result, isA<Right<Failure, FileSearchResult>>());
      expect((result as Right).value, expectedResult);
      verify(mockRepository.getFileInfo(filePath: filePath)).called(1);
    });

    test('should handle get file info failure', () async {
      // Arrange
      const filePath = '/test/file.txt';
      const failure = ApiFailure(message: 'File not found', statusCode: 404);

      when(mockRepository.getFileInfo(filePath: filePath))
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.getFileInfo(filePath: filePath);

      // Assert
      expect(result, isA<Left<Failure, FileSearchResult>>());
      expect((result as Left).value, failure);
      verify(mockRepository.getFileInfo(filePath: filePath)).called(1);
    });

    test('should add to index successfully', () async {
      // Arrange
      const path = '/test/directory';
      const includeSubdirectories = true;

      when(mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      );

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      )).called(1);
    });

    test('should handle add to index failure', () async {
      // Arrange
      const path = '/test/directory';
      const includeSubdirectories = true;
      const failure = ApiFailure(message: 'Index failed', statusCode: 500);

      when(mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      )).thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      );

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, failure);
      verify(mockRepository.addToIndex(
        path: path,
        includeSubdirectories: includeSubdirectories,
      )).called(1);
    });

    test('should remove from index successfully', () async {
      // Arrange
      const path = '/test/directory';

      when(mockRepository.removeFromIndex(path: path))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.removeFromIndex(path: path);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(mockRepository.removeFromIndex(path: path)).called(1);
    });

    test('should get search statistics successfully', () async {
      // Arrange
      final expectedStats = SearchStatistics(
        totalFiles: 1000,
        indexedFiles: 800,
        totalDirectories: 50,
        lastIndexTime: DateTime.now(),
        fileTypeDistribution: {'txt': 500, 'md': 300},
      );

      when(mockRepository.getSearchStatistics())
          .thenAnswer((_) async => Right(expectedStats));

      // Act
      final result = await mockRepository.getSearchStatistics();

      // Assert
      expect(result, isA<Right<Failure, SearchStatistics>>());
      expect((result as Right).value, expectedStats);
      verify(mockRepository.getSearchStatistics()).called(1);
    });

    test('should get watched directories successfully', () async {
      // Arrange
      final expectedDirectories = [
        const DirectoryConfig(
          path: '/test/dir1',
          isWatched: true,
          includeSubdirectories: true,
          fileExtensions: ['txt', 'md'],
        ),
        const DirectoryConfig(
          path: '/test/dir2',
          isWatched: true,
          includeSubdirectories: false,
          fileExtensions: [],
        ),
      ];

      when(mockRepository.getWatchedDirectories())
          .thenAnswer((_) async => Right(expectedDirectories));

      // Act
      final result = await mockRepository.getWatchedDirectories();

      // Assert
      expect(result, isA<Right<Failure, List<DirectoryConfig>>>());
      expect((result as Right).value, expectedDirectories);
      verify(mockRepository.getWatchedDirectories()).called(1);
    });

    test('should add watched directory successfully', () async {
      // Arrange
      const path = '/test/directory';
      const includeSubdirectories = true;
      const fileExtensions = ['txt', 'md'];

      when(mockRepository.addWatchedDirectory(
        path: path,
        includeSubdirectories: includeSubdirectories,
        fileExtensions: fileExtensions,
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.addWatchedDirectory(
        path: path,
        includeSubdirectories: includeSubdirectories,
        fileExtensions: fileExtensions,
      );

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(mockRepository.addWatchedDirectory(
        path: path,
        includeSubdirectories: includeSubdirectories,
        fileExtensions: fileExtensions,
      )).called(1);
    });

    test('should remove watched directory successfully', () async {
      // Arrange
      const path = '/test/directory';

      when(mockRepository.removeWatchedDirectory(path: path))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.removeWatchedDirectory(path: path);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(mockRepository.removeWatchedDirectory(path: path)).called(1);
    });

    test('should reindex all successfully', () async {
      // Arrange
      when(mockRepository.reindexAll())
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.reindexAll();

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(mockRepository.reindexAll()).called(1);
    });

    test('should handle reindex all failure', () async {
      // Arrange
      const failure = ApiFailure(message: 'Reindex failed', statusCode: 500);

      when(mockRepository.reindexAll())
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await mockRepository.reindexAll();

      // Assert
      expect(result, isA<Left<Failure, void>>());
      expect((result as Left).value, failure);
      verify(mockRepository.reindexAll()).called(1);
    });
  });
}
