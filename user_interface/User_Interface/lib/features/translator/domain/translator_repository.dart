import 'dart:async';

import 'translation_request_entity.dart';
import 'translation_result_entity.dart';
import 'translator_config_entity.dart';

abstract class TranslatorRepository {
  Future<TranslationResultEntity> translatePseudocode(
      TranslationRequestEntity request);

  Future<List<String>> getSupportedLanguages();

  Future<TranslatorConfigEntity> getTranslatorConfig();

  Future<void> updateTranslatorConfig(TranslatorConfigEntity config);

  Stream<TranslationResultEntity>? translateWithStreaming(
      TranslationRequestEntity request);

  /// Retrieve cached translation history (best-effort local store).
  Future<List<TranslationResultEntity>> getTranslationHistory();
}
