import 'package:freezed_annotation/freezed_annotation.dart';

part 'translator_config_entity.freezed.dart';
part 'translator_config_entity.g.dart';

@freezed
class TranslatorConfigEntity with _$TranslatorConfigEntity {
  const factory TranslatorConfigEntity({
    required String defaultLanguage,
    required List<String> availableLanguages,
    Map<String, dynamic>? modelSettings,
  }) = _TranslatorConfigEntity;

  factory TranslatorConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$TranslatorConfigEntityFromJson(json);
}
