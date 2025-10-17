import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/translator_config_entity.dart';
import '../../domain/usecases/get_supported_languages_use_case.dart';
import '../../domain/usecases/get_translator_config_use_case.dart';
import '../../domain/usecases/update_translator_config_use_case.dart';
import 'translator_loading_provider.dart';
import 'translator_repository_provider.dart';

// Provider for get supported languages use case
final getSupportedLanguagesUseCaseProvider = Provider<GetSupportedLanguagesUseCase>((ref) {
  return GetSupportedLanguagesUseCase(ref.watch(translatorRepositoryProvider));
});

// Provider for get translator config use case
final getTranslatorConfigUseCaseProvider = Provider<GetTranslatorConfigUseCase>((ref) {
  return GetTranslatorConfigUseCase(ref.watch(translatorRepositoryProvider));
});

// Provider for update translator config use case
final updateTranslatorConfigUseCaseProvider = Provider<UpdateTranslatorConfigUseCase>((ref) {
  return UpdateTranslatorConfigUseCase(ref.watch(translatorRepositoryProvider));
});

// Config state for translator
class TranslatorConfigState {
  const TranslatorConfigState({
    this.config,
    this.supportedLanguages = const [],
    this.isLoading = false,
    this.error,
  });

  final TranslatorConfigEntity? config;
  final List<String> supportedLanguages;
  final bool isLoading;
  final String? error;

  TranslatorConfigState copyWith({
    TranslatorConfigEntity? config,
    List<String>? supportedLanguages,
    bool? isLoading,
    String? error,
  }) {
    return TranslatorConfigState(
      config: config ?? this.config,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Async notifier for translator configuration
class TranslatorConfigNotifier extends AsyncNotifier<TranslatorConfigState> {
  @override
  Future<TranslatorConfigState> build() async {
    return const TranslatorConfigState();
  }

  /// Load translator configuration
  Future<void> loadConfig() async {
    final baseline = state.value ?? const TranslatorConfigState();
    ref.read(translatorLoadingProvider.notifier).setLoadingConfig(true);

    try {
      state = await AsyncValue.guard(() async {
        final useCase = ref.read(getTranslatorConfigUseCaseProvider);
        final config = await useCase();

        return baseline.copyWith(
          config: config,
          isLoading: false,
        );
      });

      if (state.hasError) {
        ref.read(translatorLoadingProvider.notifier).setConfigError(state.error.toString());
      }
    } finally {
      ref.read(translatorLoadingProvider.notifier).setLoadingConfig(false);
    }
  }

  /// Load supported languages
  Future<void> loadSupportedLanguages() async {
    state = await AsyncValue.guard(() async {
      try {
        final useCase = ref.read(getSupportedLanguagesUseCaseProvider);
        final languages = await useCase();

        return state.value!.copyWith(supportedLanguages: languages);
      } catch (e) {
        // Don't set error for languages loading failure
        // Just return current state
        return state.value!;
      }
    });
  }

  /// Update translator configuration
  Future<bool> updateConfig(TranslatorConfigEntity config) async {
    final baseline = state.value ?? const TranslatorConfigState();
    ref.read(translatorLoadingProvider.notifier).setLoadingConfig(true);

    try {
      state = await AsyncValue.guard(() async {
        final useCase = ref.read(updateTranslatorConfigUseCaseProvider);
        await useCase(config);

        return baseline.copyWith(
          config: config,
          isLoading: false,
        );
      });

      if (state.hasError) {
        ref.read(translatorLoadingProvider.notifier).setConfigError(state.error.toString());
      }
    } finally {
      ref.read(translatorLoadingProvider.notifier).setLoadingConfig(false);
    }

    return !state.hasError;
  }

  /// Update default language
  Future<bool> updateDefaultLanguage(String language) async {
    if (state.value?.config == null) return false;

    final updatedConfig = state.value!.config!.copyWith(defaultLanguage: language);
    return updateConfig(updatedConfig);
  }

  /// Add supported language
  Future<bool> addSupportedLanguage(String language) async {
    if (state.value?.config == null) return false;

    final updatedLanguages = [...state.value!.config!.availableLanguages, language];
    final updatedConfig = state.value!.config!.copyWith(availableLanguages: updatedLanguages);
    return updateConfig(updatedConfig);
  }

  /// Remove supported language
  Future<bool> removeSupportedLanguage(String language) async {
    if (state.value?.config == null) return false;

    final updatedLanguages = state.value!.config!.availableLanguages
        .where((lang) => lang != language)
        .toList();
    final updatedConfig = state.value!.config!.copyWith(availableLanguages: updatedLanguages);
    return updateConfig(updatedConfig);
  }

  /// Get current default language
  String? get currentDefaultLanguage {
    return state.value?.config?.defaultLanguage;
  }

  /// Get available languages
  List<String> get availableLanguages {
    return state.value?.config?.availableLanguages ?? [];
  }

  /// Check if language is supported
  bool isLanguageSupported(String language) {
    return state.value?.supportedLanguages.contains(language) ?? false;
  }

  /// Get model settings
  Map<String, dynamic>? get modelSettings {
    return state.value?.config?.modelSettings;
  }

  /// Update model settings
  Future<bool> updateModelSettings(Map<String, dynamic> settings) async {
    if (state.value?.config == null) return false;

    final updatedConfig = state.value!.config!.copyWith(modelSettings: settings);
    return updateConfig(updatedConfig);
  }

  /// Reset configuration to defaults
  Future<bool> resetToDefaults() async {
    // Create default config
    final defaultConfig = TranslatorConfigEntity(
      defaultLanguage: 'python',
      availableLanguages: ['python', 'javascript', 'java', 'cpp', 'csharp'],
      modelSettings: {},
    );
    return updateConfig(defaultConfig);
  }

  /// Clear error
  Future<void> clearError() async {
    state = await AsyncValue.guard(() async {
      return state.value!.copyWith(error: null);
    });
  }

  /// Reset state
  Future<void> reset() async {
    state = await AsyncValue.guard(() async {
      return const TranslatorConfigState();
    });
  }
}

// Provider for translator configuration
final translatorConfigProvider = AsyncNotifierProvider<TranslatorConfigNotifier, TranslatorConfigState>(
  () => TranslatorConfigNotifier(),
);

// Computed provider for current config
final currentTranslatorConfigProvider = Provider<TranslatorConfigEntity?>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.config,
    orElse: () => null,
  );
});

// Computed provider for supported languages
final supportedLanguagesProvider = Provider<List<String>>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.supportedLanguages,
    orElse: () => [],
  );
});

// Computed provider for default language
final defaultLanguageProvider = Provider<String?>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.config?.defaultLanguage,
    orElse: () => null,
  );
});

// Computed provider for available languages
final availableLanguagesProvider = Provider<List<String>>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.config?.availableLanguages ?? [],
    orElse: () => [],
  );
});

// Computed provider for config loading state
final isLoadingTranslatorConfigProvider = Provider<bool>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.isLoading,
    orElse: () => false,
  );
});

// Computed provider for config error
final translatorConfigErrorProvider = Provider<String?>((ref) {
  return ref.watch(translatorConfigProvider).maybeWhen(
    data: (state) => state.error,
    orElse: () => null,
  );
});
