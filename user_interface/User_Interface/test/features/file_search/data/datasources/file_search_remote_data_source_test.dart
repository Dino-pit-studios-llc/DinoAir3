import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_dash/features/file_search/data/datasources/file_search_remote_data_source.dart';
import 'package:crypto_dash/core/errors/exceptions.dart';

// Generate mock class
@GenerateMocks([Dio])
import 'file_search_remote_data_source_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late FileSearchRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = FileSearchRemoteDataSourceImpl(
      client: mockDio,
      baseUrl: 'http://localhost:8000/api/v1/file_search',
    );
  });

  group('FileSearchRemoteDataSourceImpl', () {
    group('searchFiles', () {
      test('should return search results on successful response', () async {
        // Arrange
        const query = 'test query';
        final responseData = {
          'results': [
            {
              'file_path': '/test/file1.txt',
              'file_name': 'file1.txt',
              'file_type': 'txt',
              'file_size': 1024,
              'last_modified': '2024-01-01T00:00:00Z',
              'relevance_score': 0.95,
              'matched_keywords': ['test'],
            },
          ],
        };

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await dataSource.searchFiles(query: query);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.filePath, '/test/file1.txt');
        expect(result.first.fileName, 'file1.txt');
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: {
            'query': query,
          },
        )).called(1);
      });

      test('should throw ServerException on non-200 response', () async {
        // Arrange
        const query = 'test query';

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          data: {'error': 'Bad request'},
          statusCode: 400,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.searchFiles(query: query),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: {
            'query': query,
          },
        )).called(1);
      });

      test('should throw ServerException on DioException', () async {
        // Arrange
        const query = 'test query';

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          error: 'Network error',
        ));

        // Act & Assert
        expect(
          () => dataSource.searchFiles(query: query),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: {
            'query': query,
          },
        )).called(1);
      });

      test('should include optional parameters in request', () async {
        // Arrange
        const query = 'test query';
        const fileTypes = ['txt', 'md'];
        const directories = ['/docs', '/src'];
        const maxResults = 50;

        final responseData = {'results': []};

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        await dataSource.searchFiles(
          query: query,
          fileTypes: fileTypes,
          directories: directories,
          maxResults: maxResults,
        );

        // Assert
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/search',
          data: {
            'query': query,
            'file_types': fileTypes,
            'directories': directories,
            'max_results': maxResults,
          },
        )).called(1);
      });
    });

    group('getFileInfo', () {
      test('should return file info on successful response', () async {
        // Arrange
        const filePath = '/test/file.txt';
        final responseData = {
          'file_path': filePath,
          'file_name': 'file.txt',
          'file_type': 'txt',
          'file_size': 2048,
          'last_modified': '2024-01-01T00:00:00Z',
          'relevance_score': 1.0,
          'matched_keywords': ['test'],
        };

        when(mockDio.get(
          'http://localhost:8000/api/v1/file_search/info',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await dataSource.getFileInfo(filePath);

        // Assert
        expect(result.filePath, filePath);
        expect(result.fileName, 'file.txt');
        verify(mockDio.get(
          'http://localhost:8000/api/v1/file_search/info',
          queryParameters: {'file_path': filePath},
        )).called(1);
      });

      test('should throw ServerException on non-200 response', () async {
        // Arrange
        const filePath = '/test/file.txt';

        when(mockDio.get(
          'http://localhost:8000/api/v1/file_search/info',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          data: {'error': 'File not found'},
          statusCode: 404,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.getFileInfo(filePath),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.get(
          'http://localhost:8000/api/v1/file_search/info',
          queryParameters: {'file_path': filePath},
        )).called(1);
      });
    });

    group('addToIndex', () {
      test('should complete successfully on 200 response', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/index',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.addToIndex(path, includeSubdirectories),
          returnsNormally,
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/index',
          data: {
            'path': path,
            'include_subdirectories': includeSubdirectories,
          },
        )).called(1);
      });

      test('should throw ServerException on non-200/201 response', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/index',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          statusCode: 400,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.addToIndex(path, includeSubdirectories),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/index',
          data: {
            'path': path,
            'include_subdirectories': includeSubdirectories,
          },
        )).called(1);
      });
    });

    group('removeFromIndex', () {
      test('should complete successfully on 200 response', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/index',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.removeFromIndex(path),
          returnsNormally,
        );
        verify(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/index',
          queryParameters: {'path': path},
        )).called(1);
      });

      test('should throw ServerException on non-200/204 response', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/index',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          statusCode: 400,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.removeFromIndex(path),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/index',
          queryParameters: {'path': path},
        )).called(1);
      });
    });

    group('getSearchStatistics', () {
      test('should return statistics on successful response', () async {
        // Arrange
        final responseData = {
          'total_files': 1000,
          'indexed_files': 800,
          'total_directories': 50,
          'last_index_time': '2024-01-01T00:00:00Z',
          'file_type_distribution': {'txt': 500, 'md': 300},
        };

        when(mockDio.get('http://localhost:8000/api/v1/file_search/stats'))
            .thenAnswer((_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await dataSource.getSearchStatistics();

        // Assert
        expect(result.totalFiles, 1000);
        expect(result.indexedFiles, 800);
        expect(result.totalDirectories, 50);
        verify(mockDio.get('http://localhost:8000/api/v1/file_search/stats')).called(1);
      });

      test('should throw ServerException on non-200 response', () async {
        // Arrange
        when(mockDio.get('http://localhost:8000/api/v1/file_search/stats'))
            .thenAnswer((_) async => Response(
          data: {'error': 'Stats unavailable'},
          statusCode: 500,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.getSearchStatistics(),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.get('http://localhost:8000/api/v1/file_search/stats')).called(1);
      });
    });

    group('getWatchedDirectories', () {
      test('should return directories on successful response', () async {
        // Arrange
        final responseData = {
          'directories': [
            {
              'path': '/test/dir1',
              'is_watched': true,
              'include_subdirectories': true,
              'file_extensions': ['txt', 'md'],
            },
          ],
        };

        when(mockDio.get('http://localhost:8000/api/v1/file_search/directories'))
            .thenAnswer((_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await dataSource.getWatchedDirectories();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.path, '/test/dir1');
        expect(result.first.isWatched, true);
        verify(mockDio.get('http://localhost:8000/api/v1/file_search/directories')).called(1);
      });

      test('should throw ServerException on non-200 response', () async {
        // Arrange
        when(mockDio.get('http://localhost:8000/api/v1/file_search/directories'))
            .thenAnswer((_) async => Response(
          data: {'error': 'Directories unavailable'},
          statusCode: 500,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.getWatchedDirectories(),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.get('http://localhost:8000/api/v1/file_search/directories')).called(1);
      });
    });

    group('addWatchedDirectory', () {
      test('should complete successfully on 200 response', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;
        const extensions = ['txt', 'md'];

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/directories',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.addWatchedDirectory(path, includeSubdirectories, extensions),
          returnsNormally,
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/directories',
          data: {
            'path': path,
            'include_subdirectories': includeSubdirectories,
            'file_extensions': extensions,
          },
        )).called(1);
      });

      test('should throw ServerException on non-200/201 response', () async {
        // Arrange
        const path = '/test/directory';
        const includeSubdirectories = true;
        const extensions = ['txt', 'md'];

        when(mockDio.post(
          'http://localhost:8000/api/v1/file_search/directories',
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          statusCode: 400,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.addWatchedDirectory(path, includeSubdirectories, extensions),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post(
          'http://localhost:8000/api/v1/file_search/directories',
          data: {
            'path': path,
            'include_subdirectories': includeSubdirectories,
            'file_extensions': extensions,
          },
        )).called(1);
      });
    });

    group('removeWatchedDirectory', () {
      test('should complete successfully on 200 response', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/directories',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.removeWatchedDirectory(path),
          returnsNormally,
        );
        verify(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/directories',
          queryParameters: {'path': path},
        )).called(1);
      });

      test('should throw ServerException on non-200/204 response', () async {
        // Arrange
        const path = '/test/directory';

        when(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/directories',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
          statusCode: 400,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.removeWatchedDirectory(path),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.delete(
          'http://localhost:8000/api/v1/file_search/directories',
          queryParameters: {'path': path},
        )).called(1);
      });
    });

    group('reindexAll', () {
      test('should complete successfully on valid response', () async {
        // Arrange
        when(mockDio.post('http://localhost:8000/api/v1/file_search/reindex'))
            .thenAnswer((_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.reindexAll(),
          returnsNormally,
        );
        verify(mockDio.post('http://localhost:8000/api/v1/file_search/reindex')).called(1);
      });

      test('should throw ServerException on error response', () async {
        // Arrange
        when(mockDio.post('http://localhost:8000/api/v1/file_search/reindex'))
            .thenAnswer((_) async => Response(
          statusCode: 500,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        expect(
          () => dataSource.reindexAll(),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post('http://localhost:8000/api/v1/file_search/reindex')).called(1);
      });

      test('should throw ServerException on DioException', () async {
        // Arrange
        when(mockDio.post('http://localhost:8000/api/v1/file_search/reindex'))
            .thenThrow(DioException(
          requestOptions: RequestOptions(),
          error: 'Network error',
        ));

        // Act & Assert
        expect(
          () => dataSource.reindexAll(),
          throwsA(isA<ServerException>()),
        );
        verify(mockDio.post('http://localhost:8000/api/v1/file_search/reindex')).called(1);
      });
    });
  });
}
