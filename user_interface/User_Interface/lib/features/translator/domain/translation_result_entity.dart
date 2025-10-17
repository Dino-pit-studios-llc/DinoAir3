import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_result_entity.freezed.dart';
part 'translation_result_entity.g.dart';

@freezed
class TranslationResultEntity with _$TranslationResultEntity {
  const factory TranslationResultEntity({
    required String id,
    required String requestId,
    required String translatedCode,
    required String language,
    required double confidence,
    Map<String, dynamic>? metadata,
  }) = _TranslationResultEntity;

  factory TranslationResultEntity.fromJson(Map<String, dynamic> json) =>
      _$TranslationResultEntityFromJson(json);
}
