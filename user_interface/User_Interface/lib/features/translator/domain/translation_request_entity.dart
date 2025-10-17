import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_request_entity.freezed.dart';
part 'translation_request_entity.g.dart';

@freezed
class TranslationRequestEntity with _$TranslationRequestEntity {
  const factory TranslationRequestEntity({
    required String id,
    required String pseudocode,
    required String targetLanguage,
    Map<String, dynamic>? options,
  }) = _TranslationRequestEntity;

  factory TranslationRequestEntity.fromJson(Map<String, dynamic> json) =>
      _$TranslationRequestEntityFromJson(json);
}
