import 'package:crypto_dash/core/errors/failure.dart';
import 'package:crypto_dash/features/translator/data/translator_dto.dart';
import 'package:crypto_dash/features/translator/data/translator_local_data_source.dart';
import 'package:crypto_dash/features/translator/data/translator_remote_data_source.dart';
import 'package:crypto_dash/features/translator/data/translator_repository_impl.dart';
import 'package:crypto_dash/features/translator/domain/translation_request_entity.dart';
import 'package:crypto_dash/features/translator/domain/translator_config_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'translator_repository_impl_test.mocks.dart';

@GenerateMocks([TranslatorRemoteDataSource, TranslatorLocalDataSource])
void main() {
  late TranslatorRepositoryImpl repository;
  late MockTranslatorRemoteDataSource mockRemoteDataSource;
  late MockTranslatorLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockTranslatorRemoteDataSource();
    mockLocalDataSource = MockTranslatorLocalDataSource();
    repository = TranslatorRepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
    );
  });

  group('TranslatorRepositoryImpl - translatePseudocode', () {
    const tRequest = TranslationRequestEntity(
      id: 'req-123',
      pseudocode: 'IF x > 0 THEN PRINT x',
      targetLanguage: 'python',
    );

    const tResultDto = TranslationResponseDto(
      translatedCode: 'if x > 0:\n    print(x)',
      language: 'python',
      confidence: 0.95,
      requestId: 'req-123',
    );

    test('should return TranslationResultEntity when translation succeeds',
        () async {
      // Arrange
      when(mockRemoteDataSource.translatePseudocode(any))
          .thenAnswer((_) async => tResultDto);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveTranslation(any))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.translatePseudocode(tRequest);

      // Assert
      expect(result.translatedCode, equals('if x > 0:\n    print(x)'));
      expect(result.language, equals('python'));
      expect(result.confidence, equals(0.95));
      verify(mockRemoteDataSource.translatePseudocode(any)).called(1);
    });

    test('should cache translation result locally after successful translation',
        () async {
      // Arrange
      when(mockRemoteDataSource.translatePseudocode(any))
          .thenAnswer((_) async => tResultDto);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveTranslation(any))
          .thenAnswer((_) async => null);

      // Act
      await repository.translatePseudocode(tRequest);

      // Assert
      verify(mockLocalDataSource.saveTranslation(any)).called(1);
    });

    test('should not fail when local cache save fails', () async {
      // Arrange
      when(mockRemoteDataSource.translatePseudocode(any))
          .thenAnswer((_) async => tResultDto);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveTranslation(any))
          .thenThrow(Exception('Cache write error'));

      // Act
      final result = await repository.translatePseudocode(tRequest);

      // Assert - should still return result even though cache failed
      expect(result.translatedCode, equals('if x > 0:\n    print(x)'));
    });

    test('should throw Failure when remote translation fails', () async {
      // Arrange
      when(mockRemoteDataSource.translatePseudocode(any))
          .thenThrow(NetworkFailure(message: 'Connection error'));
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => repository.translatePseudocode(tRequest),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('TranslatorRepositoryImpl - getSupportedLanguages', () {
    final tLanguages = ['python', 'javascript', 'java', 'csharp'];

    test('should return list of supported languages from remote', () async {
      // Arrange
      when(mockRemoteDataSource.getSupportedLanguages())
          .thenAnswer((_) async => tLanguages);

      // Act
      final result = await repository.getSupportedLanguages();

      // Assert
      expect(result, equals(tLanguages));
      verify(mockRemoteDataSource.getSupportedLanguages()).called(1);
    });

    test('should return empty list when remote fails', () async {
      // Arrange
      when(mockRemoteDataSource.getSupportedLanguages())
          .thenThrow(NetworkFailure(message: 'Connection error'));

      // Act
      final result = await repository.getSupportedLanguages();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('TranslatorRepositoryImpl - getTranslatorConfig', () {
    const tConfigDto = TranslatorConfigDto(
      defaultLanguage: 'python',
      availableLanguages: ['python', 'javascript', 'java'],
    );

    test('should return config from remote data source', () async {
      // Arrange
      when(mockRemoteDataSource.getTranslatorConfig())
          .thenAnswer((_) async => tConfigDto);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getTranslatorConfig();

      // Assert
      expect(result.defaultLanguage, equals('python'));
      expect(result.availableLanguages, contains('python'));
      verify(mockRemoteDataSource.getTranslatorConfig()).called(1);
    });

    test('should cache config locally after successful remote fetch',
        () async {
      // Arrange
      when(mockRemoteDataSource.getTranslatorConfig())
          .thenAnswer((_) async => tConfigDto);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act
      await repository.getTranslatorConfig();

      // Assert
      verify(mockLocalDataSource.saveConfig(any)).called(1);
    });

    test('should return cached config when remote fails', () async {
      // Arrange
      const tCachedConfig = TranslatorConfigEntity(
        defaultLanguage: 'python',
        availableLanguages: ['python', 'javascript'],
      );

      when(mockRemoteDataSource.getTranslatorConfig())
          .thenThrow(NetworkFailure(message: 'Connection error'));
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.getCachedConfig())
          .thenAnswer((_) async => tCachedConfig);

      // Act
      final result = await repository.getTranslatorConfig();

      // Assert
      expect(result, equals(tCachedConfig));
      verify(mockLocalDataSource.getCachedConfig()).called(1);
    });

    test('should throw Failure when both remote and cache fail', () async {
      // Arrange
      when(mockRemoteDataSource.getTranslatorConfig())
          .thenThrow(NetworkFailure(message: 'Connection error'));
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.getCachedConfig())
          .thenThrow(Exception('Cache read error'));

      // Act & Assert
      expect(
        () => repository.getTranslatorConfig(),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('TranslatorRepositoryImpl - updateTranslatorConfig', () {
    const tConfigEntity = TranslatorConfigEntity(
      defaultLanguage: 'javascript',
      availableLanguages: ['python', 'javascript', 'java'],
    );

    test('should update config via remote data source', () async {
      // Arrange
      when(mockRemoteDataSource.updateTranslatorConfig(any))
          .thenAnswer((_) async => null);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act
      await repository.updateTranslatorConfig(tConfigEntity);

      // Assert
      verify(mockRemoteDataSource.updateTranslatorConfig(any)).called(1);
    });

    test('should update local cache after successful remote update', () async {
      // Arrange
      when(mockRemoteDataSource.updateTranslatorConfig(any))
          .thenAnswer((_) async => null);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act
      await repository.updateTranslatorConfig(tConfigEntity);

      // Assert
      verify(mockLocalDataSource.saveConfig(tConfigEntity)).called(1);
    });

    test('should not fail when local cache update fails', () async {
      // Arrange
      when(mockRemoteDataSource.updateTranslatorConfig(any))
          .thenAnswer((_) async => null);
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockLocalDataSource.saveConfig(any))
          .thenThrow(Exception('Cache write error'));

      // Act & Assert - should not throw
      await repository.updateTranslatorConfig(tConfigEntity);

      // Verify remote update still happened
      verify(mockRemoteDataSource.updateTranslatorConfig(any)).called(1);
    });

    test('should throw Failure when remote update fails', () async {
      // Arrange
      when(mockRemoteDataSource.updateTranslatorConfig(any))
          .thenThrow(NetworkFailure(message: 'Connection error'));
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => repository.updateTranslatorConfig(tConfigEntity),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('TranslatorRepositoryImpl - local initialization', () {
    test('should initialize local storage only once', () async {
      // Arrange
      when(mockLocalDataSource.init()).thenAnswer((_) async => null);
      when(mockRemoteDataSource.getTranslatorConfig()).thenAnswer(
        (_) async => const TranslatorConfigDto(
          defaultLanguage: 'python',
          availableLanguages: ['python'],
        ),
      );
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act - call twice
      await repository.getTranslatorConfig();
      await repository.getTranslatorConfig();

      // Assert - init should only be called once
      verify(mockLocalDataSource.init()).called(1);
    });

    test('should retry initialization if first attempt fails', () async {
      // Arrange
      var initCallCount = 0;
      when(mockLocalDataSource.init()).thenAnswer((_) async {
        initCallCount++;
        if (initCallCount == 1) {
          throw Exception('Init failed');
        }
        return null;
      });
      when(mockRemoteDataSource.getTranslatorConfig()).thenAnswer(
        (_) async => const TranslatorConfigDto(
          defaultLanguage: 'python',
          availableLanguages: ['python'],
        ),
      );
      when(mockLocalDataSource.saveConfig(any)).thenAnswer((_) async => null);

      // Act - first call fails, second succeeds
      await repository.getTranslatorConfig(); // Fails silently
      await repository.getTranslatorConfig(); // Retries init

      // Assert - init should be called twice
      verify(mockLocalDataSource.init()).called(2);
    });
  });
}
