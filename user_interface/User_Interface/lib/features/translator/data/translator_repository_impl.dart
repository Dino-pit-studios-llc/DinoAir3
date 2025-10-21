import 'dart:async';

import 'package:crypto_dash/core/errors/error_handler.dart';
import 'package:crypto_dash/features/translator/data/translator_mapper.dart';
import 'package:crypto_dash/features/translator/data/translator_remote_data_source.dart';
import 'package:crypto_dash/features/translator/data/translator_local_data_source.dart';
import 'package:crypto_dash/features/translator/domain/translation_request_entity.dart';
import 'package:crypto_dash/features/translator/domain/translation_result_entity.dart';
import 'package:crypto_dash/features/translator/domain/translator_config_entity.dart';
import 'package:crypto_dash/features/translator/domain/translator_repository.dart';

class TranslatorRepositoryImpl implements TranslatorRepository {
  TranslatorRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  final TranslatorRemoteDataSource _remoteDataSource;
  final TranslatorLocalDataSource _localDataSource;

  // Lazy one-time initializer for local cache (Hive)
  Future<void>? _localInitFuture;
  bool _localInitialized = false;

  Future<void> _ensureLocalInit() async {
    if (_localInitialized) return;

    if (_localInitFuture != null) {
      await _localInitFuture;
      return;
    }

    _localInitFuture = _localDataSource.init();
    try {
      await _localInitFuture;
      _localInitialized = true;
      // Optional: debug log
      // print('Translator local cache initialized');
    } catch (e) {
      // Reset so future attempts can retry
      _localInitFuture = null;
      rethrow;
    }
  }

  Future<void> _ensureLocalInitSafe() async {
    if (_localInitialized) return;
    try {
      await _ensureLocalInit();
    } catch (e) {
      // Log and continue; do not break caller flows
      // TODO: replace with proper logger
      print('Translator local cache init failed: $e');
    }
  }

  @override
  Future<TranslationResultEntity> translatePseudocode(
      TranslationRequestEntity request) {
    return guardFuture(() async {
      // Convert entity to DTO for remote call
      final requestDto = TranslatorMapper.fromTranslationRequestEntity(request);

      // Call remote data source
      final responseDto =
          await _remoteDataSource.translatePseudocode(requestDto);

      // Convert response DTO to entity
      final result = TranslatorMapper.toTranslationResultEntity(responseDto);

      // Cache the result locally
      await _ensureLocalInitSafe();
      try {
        await _localDataSource.saveTranslation(result);
      } catch (e) {
        // Log error but don't fail the operation
        // TODO: Add proper logging
        print('Failed to cache translation: $e');
      }

      return result;
    });
  }

  @override
  Future<List<String>> getSupportedLanguages() {
    return guardFuture(() async {
      try {
        // Try remote first
        return await _remoteDataSource.getSupportedLanguages();
      } catch (e) {
        // If remote fails, try to return cached data
        // For now, return empty list as fallback
        // TODO: Implement proper fallback to cached languages if available
        return const [];
      }
    });
  }

  @override
  Future<TranslatorConfigEntity> getTranslatorConfig() {
    return guardFuture(() async {
      await _ensureLocalInitSafe();
      try {
        // Try remote first
        final configDto = await _remoteDataSource.getTranslatorConfig();
        final config = TranslatorMapper.toTranslatorConfigEntity(configDto);

        // Cache the config locally
        try {
          await _localDataSource.saveConfig(config);
        } catch (e) {
          // Log error but don't fail the operation
          print('Failed to cache translator config: $e');
        }

        return config;
      } catch (e) {
        // If remote fails, try to return cached config
        try {
          final cachedConfig = await _localDataSource.getCachedConfig();
          if (cachedConfig != null) {
            return cachedConfig;
          }
        } catch (cacheError) {
          // Log error but don't fail the operation
          print('Failed to get cached config: $cacheError');
        }

        // If both remote and cache fail, throw the original error
        rethrow;
      }
    });
  }

  @override
  Future<void> updateTranslatorConfig(TranslatorConfigEntity config) {
    return guardFuture(() async {
      await _ensureLocalInitSafe();
      // Convert entity to DTO for remote call
      final configDto = TranslatorMapper.fromTranslatorConfigEntity(config);

      // Update remote config
      await _remoteDataSource.updateTranslatorConfig(configDto);

      // Update local cache
      try {
        await _localDataSource.saveConfig(config);
      } catch (e) {
        // Log error but don't fail the operation
        print('Failed to cache updated translator config: $e');
      }
    });
  }

  @override
  Stream<TranslationResultEntity>? translateWithStreaming(
      TranslationRequestEntity request) {
    try {
      // Fire-and-forget local init to prepare cache for streaming saves
      // ignore: unawaited_futures
      _ensureLocalInitSafe();
      // Convert entity to DTO for remote call
      final requestDto = TranslatorMapper.fromTranslationRequestEntity(request);

      // Get streaming response from remote data source
      final stream = _remoteDataSource.translateWithStreaming(requestDto);

      if (stream == null) {
        return null; // Streaming not supported
      }

      // Convert DTO stream to entity stream
      return stream.map((dto) {
        final entity = TranslatorMapper.toTranslationResultEntity(dto);

        // Cache each streaming result locally
        try {
          _localDataSource.saveTranslation(entity);
        } catch (e) {
          // Log error but don't fail the operation
          print('Failed to cache streaming translation: $e');
        }

        return entity;
      }).asBroadcastStream();
    } catch (e) {
      // If streaming fails, return null
      return null;
    }
  }

  /// Get translation history from local cache
  Future<List<TranslationResultEntity>> getTranslationHistory() {
    return guardFuture(() async {
      await _ensureLocalInit();
      return await _localDataSource.getTranslationHistory();
    });
  }

  /// Clear translation history from local cache
  Future<void> clearTranslationHistory() {
    return guardFuture(() async {
      await _ensureLocalInit();
      await _localDataSource.clearHistory();
    });
  }

  /// Clear translator config from local cache
  Future<void> clearTranslatorConfig() {
    return guardFuture(() async {
      await _ensureLocalInit();
      await _localDataSource.clearConfig();
    });
  }

  /// Clear all cached translator data
  Future<void> clearAllCache() {
    return guardFuture(() async {
      await _ensureLocalInit();
      await _localDataSource.clearAllCache();
    });
  }
}
