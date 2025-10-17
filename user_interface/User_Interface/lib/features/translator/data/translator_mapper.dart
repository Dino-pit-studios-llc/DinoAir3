import 'package:crypto_dash/features/translator/data/translator_dto.dart';
import 'package:crypto_dash/features/translator/domain/translation_request_entity.dart';
import 'package:crypto_dash/features/translator/domain/translation_result_entity.dart';
import 'package:crypto_dash/features/translator/domain/translator_config_entity.dart';

class TranslatorMapper {
  const TranslatorMapper._();

  // Translation Request Mappers
  static TranslationRequestDto fromTranslationRequestEntity(TranslationRequestEntity entity) {
    return TranslationRequestDto(
      pseudocode: entity.pseudocode,
      targetLanguage: entity.targetLanguage,
      options: entity.options,
    );
  }

  static TranslationRequestEntity toTranslationRequestEntity(TranslationRequestDto dto) {
    return TranslationRequestEntity(
      id: '', // DTO doesn't have ID, will be set by repository
      pseudocode: dto.pseudocode,
      targetLanguage: dto.targetLanguage,
      options: dto.options,
    );
  }

  // Translation Result Mappers
  static TranslationResponseDto fromTranslationResultEntity(TranslationResultEntity entity) {
    return TranslationResponseDto(
      translatedCode: entity.translatedCode,
      language: entity.language,
      confidence: entity.confidence,
      metadata: entity.metadata,
      requestId: entity.requestId,
    );
  }

  static TranslationResultEntity toTranslationResultEntity(TranslationResponseDto dto) {
    return TranslationResultEntity(
      id: '', // DTO doesn't have ID, will be set by repository
      requestId: dto.requestId ?? '',
      translatedCode: dto.translatedCode,
      language: dto.language,
      confidence: dto.confidence,
      metadata: dto.metadata,
    );
  }

  // Translator Config Mappers
  static TranslatorConfigDto fromTranslatorConfigEntity(TranslatorConfigEntity entity) {
    return TranslatorConfigDto(
      defaultLanguage: entity.defaultLanguage,
      availableLanguages: entity.availableLanguages,
      modelSettings: entity.modelSettings,
    );
  }

  static TranslatorConfigEntity toTranslatorConfigEntity(TranslatorConfigDto dto) {
    return TranslatorConfigEntity(
      defaultLanguage: dto.defaultLanguage,
      availableLanguages: List<String>.from(dto.availableLanguages),
      modelSettings: dto.modelSettings,
    );
  }

  // List Mappers
  static List<TranslationRequestEntity> toTranslationRequestEntities(List<TranslationRequestDto> dtos) {
    return dtos.map(toTranslationRequestEntity).toList(growable: false);
  }

  static List<TranslationRequestDto> fromTranslationRequestEntities(List<TranslationRequestEntity> entities) {
    return entities.map(fromTranslationRequestEntity).toList(growable: false);
  }

  static List<TranslationResultEntity> toTranslationResultEntities(List<TranslationResponseDto> dtos) {
    return dtos.map(toTranslationResultEntity).toList(growable: false);
  }

  static List<TranslationResponseDto> fromTranslationResultEntities(List<TranslationResultEntity> entities) {
    return entities.map(fromTranslationResultEntity).toList(growable: false);
  }

  static List<TranslatorConfigEntity> toTranslatorConfigEntities(List<TranslatorConfigDto> dtos) {
    return dtos.map(toTranslatorConfigEntity).toList(growable: false);
  }

  static List<TranslatorConfigDto> fromTranslatorConfigEntities(List<TranslatorConfigEntity> entities) {
    return entities.map(fromTranslatorConfigEntity).toList(growable: false);
  }
}
