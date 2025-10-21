import 'package:meta/meta.dart';

// Top-level helper for normalizing language lists from JSON
List<String> _normalizeLanguages(Object? raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw
        .map((value) => value == null ? '' : value.toString())
        .where((value) => value.isNotEmpty)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

@immutable
class TranslationRequestDto {
  const TranslationRequestDto({
    required this.pseudocode,
    required this.targetLanguage,
    this.options,
  });

  final String pseudocode;
  final String targetLanguage;
  final Map<String, dynamic>? options;

  factory TranslationRequestDto.fromJson(Map<String, dynamic> json) {
    return TranslationRequestDto(
      pseudocode: json['pseudocode']?.toString() ?? '',
      targetLanguage: json['target_language']?.toString() ??
          json['targetLanguage']?.toString() ??
          '',
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pseudocode': pseudocode,
      'target_language': targetLanguage,
      if (options != null) 'options': options,
    };
  }

  TranslationRequestDto copyWith({
    String? pseudocode,
    String? targetLanguage,
    Map<String, dynamic>? options,
  }) {
    return TranslationRequestDto(
      pseudocode: pseudocode ?? this.pseudocode,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      options: options ?? this.options,
    );
  }
}

@immutable
class TranslationResponseDto {
  const TranslationResponseDto({
    required this.translatedCode,
    required this.language,
    required this.confidence,
    this.metadata,
    this.requestId,
  });

  final String translatedCode;
  final String language;
  final double confidence;
  final Map<String, dynamic>? metadata;
  final String? requestId;

  factory TranslationResponseDto.fromJson(Map<String, dynamic> json) {
    return TranslationResponseDto(
      translatedCode: json['translated_code']?.toString() ??
          json['translatedCode']?.toString() ??
          '',
      language: json['language']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      requestId:
          json['request_id']?.toString() ?? json['requestId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translated_code': translatedCode,
      'language': language,
      'confidence': confidence,
      if (metadata != null) 'metadata': metadata,
      if (requestId != null) 'request_id': requestId,
    };
  }

  TranslationResponseDto copyWith({
    String? translatedCode,
    String? language,
    double? confidence,
    Map<String, dynamic>? metadata,
    String? requestId,
  }) {
    return TranslationResponseDto(
      translatedCode: translatedCode ?? this.translatedCode,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      requestId: requestId ?? this.requestId,
    );
  }
}

@immutable
class TranslatorConfigDto {
  const TranslatorConfigDto({
    required this.defaultLanguage,
    required this.availableLanguages,
    this.modelSettings,
  });

  final String defaultLanguage;
  final List<String> availableLanguages;
  final Map<String, dynamic>? modelSettings;

  factory TranslatorConfigDto.fromJson(Map<String, dynamic> json) {
    return TranslatorConfigDto(
      defaultLanguage: json['default_language']?.toString() ??
          json['defaultLanguage']?.toString() ??
          '',
      availableLanguages: _normalizeLanguages(
          json['available_languages'] ?? json['availableLanguages']),
      modelSettings: json['model_settings'] as Map<String, dynamic>? ??
          json['modelSettings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_language': defaultLanguage,
      'available_languages': availableLanguages,
      if (modelSettings != null) 'model_settings': modelSettings,
    };
  }

  TranslatorConfigDto copyWith({
    String? defaultLanguage,
    List<String>? availableLanguages,
    Map<String, dynamic>? modelSettings,
  }) {
    return TranslatorConfigDto(
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      modelSettings: modelSettings ?? this.modelSettings,
    );
  }
}

@immutable
class TranslationResultDto {
  const TranslationResultDto({
    required this.translatedCode,
    required this.language,
    required this.confidence,
    this.metadata,
    this.requestId,
  });

  final String translatedCode;
  final String language;
  final double confidence;
  final Map<String, dynamic>? metadata;
  final String? requestId;

  factory TranslationResultDto.fromJson(Map<String, dynamic> json) {
    return TranslationResultDto(
      translatedCode: json['translated_code']?.toString() ??
          json['translatedCode']?.toString() ??
          '',
      language: json['language']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      requestId:
          json['request_id']?.toString() ?? json['requestId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translated_code': translatedCode,
      'language': language,
      'confidence': confidence,
      if (metadata != null) 'metadata': metadata,
      if (requestId != null) 'request_id': requestId,
    };
  }

  TranslationResultDto copyWith({
    String? translatedCode,
    String? language,
    double? confidence,
    Map<String, dynamic>? metadata,
    String? requestId,
  }) {
    return TranslationResultDto(
      translatedCode: translatedCode ?? this.translatedCode,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
      requestId: requestId ?? this.requestId,
    );
  }
}

@immutable
class SupportedLanguagesDto {
  const SupportedLanguagesDto({
    required this.languages,
    this.metadata,
  });

  final List<String> languages;
  final Map<String, dynamic>? metadata;

  factory SupportedLanguagesDto.fromJson(Map<String, dynamic> json) {
    return SupportedLanguagesDto(
      languages: _normalizeLanguages(json['languages']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languages': languages,
      if (metadata != null) 'metadata': metadata,
    };
  }

  SupportedLanguagesDto copyWith({
    List<String>? languages,
    Map<String, dynamic>? metadata,
  }) {
    return SupportedLanguagesDto(
      languages: languages ?? this.languages,
      metadata: metadata ?? this.metadata,
    );
  }

  static List<String> _normalizeLanguages(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((value) => value == null ? '' : value.toString())
          .where((value) => value.isNotEmpty)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
