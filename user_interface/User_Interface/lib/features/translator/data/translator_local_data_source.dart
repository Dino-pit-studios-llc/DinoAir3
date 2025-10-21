import 'package:hive_flutter/hive_flutter.dart';

import 'package:crypto_dash/features/translator/domain/translation_result_entity.dart';
import 'package:crypto_dash/features/translator/domain/translator_config_entity.dart';

class TranslatorLocalDataSource {
  static const String _translationsBox = 'translator_translations';
  static const String _configBox = 'translator_config';
  static const String _configKey = 'translator_config_key';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters for complex objects
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TranslationResultAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TranslatorConfigAdapter());
    }

    // Open boxes
    await Hive.openBox<TranslationResultEntity>(_translationsBox);
    await Hive.openBox<TranslatorConfigEntity>(_configBox);
  }

  Future<void> saveTranslation(TranslationResultEntity result) async {
    final box = Hive.box<TranslationResultEntity>(_translationsBox);

    // Save translation by its ID
    await box.put(result.id, result);

    // Also save by request ID for easy retrieval
    await box.put('request_${result.requestId}_${result.id}', result);
  }

  Future<void> saveConfig(TranslatorConfigEntity config) async {
    final box = Hive.box<TranslatorConfigEntity>(_configBox);
    await box.put(_configKey, config);
  }

  Future<List<TranslationResultEntity>> getTranslationHistory() async {
    final box = Hive.box<TranslationResultEntity>(_translationsBox);

    // Filter out duplicate entries (keys starting with 'request_')
    final primaryEntries = <TranslationResultEntity>[];
    for (var key in box.keys) {
      if (key is String && key.startsWith('request_')) {
        continue; // Skip secondary entries
      }
      final entity = box.get(key);
      if (entity != null) {
        primaryEntries.add(entity);
      }
    }
    return primaryEntries;
  }

  Future<TranslatorConfigEntity?> getCachedConfig() async {
    final box = Hive.box<TranslatorConfigEntity>(_configBox);
    return box.get(_configKey);
  }

  Future<void> clearHistory() async {
    final box = Hive.box<TranslationResultEntity>(_translationsBox);
    await box.clear();
  }

  Future<void> clearConfig() async {
    final box = Hive.box<TranslatorConfigEntity>(_configBox);
    await box.delete(_configKey);
  }

  Future<void> clearAllCache() async {
    final translationsBox = Hive.box<TranslationResultEntity>(_translationsBox);
    final configBox = Hive.box<TranslatorConfigEntity>(_configBox);

    await translationsBox.clear();
    await configBox.clear();
  }

  Future<List<TranslationResultEntity>> getTranslationsByRequestId(
      String requestId) async {
    final box = Hive.box<TranslationResultEntity>(_translationsBox);

    // Look for all translations that belong to this request
    final requestTranslations = <TranslationResultEntity>[];

    for (var key in box.keys) {
      if (key is String && key.startsWith('request_$requestId')) {
        final translation = box.get(key);
        if (translation != null) {
          requestTranslations.add(translation);
        }
      }
    }

    // Sort by ID (assuming IDs are timestamp-based or sequential)
    requestTranslations.sort((a, b) => a.id.compareTo(b.id));
    return requestTranslations;
  }

  Future<void> deleteTranslation(String id) async {
    final box = Hive.box<TranslationResultEntity>(_translationsBox);

    // Delete by ID
    await box.delete(id);

    // Also try to delete by any request_* keys that might contain this ID
    final keysToDelete = <dynamic>[];
    for (var key in box.keys) {
      if (key is String && key.endsWith('_$id')) {
        keysToDelete.add(key);
      }
    }

    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }
}

// Hive adapters for complex objects
class TranslationResultAdapter extends TypeAdapter<TranslationResultEntity> {
  @override
  final int typeId = 0;

  @override
  TranslationResultEntity read(BinaryReader reader) {
    return TranslationResultEntity(
      id: reader.readString(),
      requestId: reader.readString(),
      translatedCode: reader.readString(),
      language: reader.readString(),
      confidence: reader.readDouble(),
      metadata: reader.read() as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, TranslationResultEntity obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.requestId);
    writer.writeString(obj.translatedCode);
    writer.writeString(obj.language);
    writer.writeDouble(obj.confidence);
    writer.write(obj.metadata);
  }
}

class TranslatorConfigAdapter extends TypeAdapter<TranslatorConfigEntity> {
  @override
  final int typeId = 1;

  @override
  TranslatorConfigEntity read(BinaryReader reader) {
    return TranslatorConfigEntity(
      defaultLanguage: reader.readString(),
      availableLanguages: reader.read() as List<String>,
      modelSettings: reader.read() as Map<String, dynamic>?,
    );
  }

  @override
  void write(BinaryWriter writer, TranslatorConfigEntity obj) {
    writer.writeString(obj.defaultLanguage);
    writer.write(obj.availableLanguages);
    writer.write(obj.modelSettings);
  }
}
