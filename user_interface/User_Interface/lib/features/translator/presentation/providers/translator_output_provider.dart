import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/translation_result_entity.dart';
import '../../domain/usecases/get_translator_config_use_case.dart';
import 'translator_loading_provider.dart';
import 'translator_repository_provider.dart';

// Provider for get translator config use case
final getTranslatorConfigUseCaseProvider = Provider<GetTranslatorConfigUseCase>((ref) {
  return GetTranslatorConfigUseCase(ref.watch(translatorRepositoryProvider));
});

// Output state for translator
class TranslatorOutputState {
  const TranslatorOutputState({
    this.currentResult,
    this.translationHistory = const [],
    this.isLoadingHistory = false,
    this.error,
  });

  final TranslationResultEntity? currentResult;
  final List<TranslationResultEntity> translationHistory;
  final bool isLoadingHistory;
  final String? error;

  TranslatorOutputState copyWith({
    TranslationResultEntity? currentResult,
    List<TranslationResultEntity>? translationHistory,
    bool? isLoadingHistory,
    String? error,
  }) {
    return TranslatorOutputState(
      currentResult: currentResult ?? this.currentResult,
      translationHistory: translationHistory ?? this.translationHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}

// Async notifier for translator output
class TranslatorOutputNotifier extends AsyncNotifier<TranslatorOutputState> {
  @override
  Future<TranslatorOutputState> build() async {
    return const TranslatorOutputState();
  }

  /// Set translation result
  Future<void> setTranslationResult(TranslationResultEntity result) async {
    state = await AsyncValue.guard(() async {
      return state.value!.copyWith(currentResult: result);
    });
  }

  /// Clear current translation result
  Future<void> clearCurrentResult() async {
    state = await AsyncValue.guard(() async {
      return state.value!.copyWith(currentResult: null);
    });
  }

  /// Load translation history
  Future<void> loadTranslationHistory() async {
    final current = state.value ?? const TranslatorOutputState();
    ref.read(translatorLoadingProvider.notifier).setLoadingHistory(true);

    try {
      state = await AsyncValue.guard(() async {
        final history = await _getTranslationHistory();
        return current.copyWith(
          translationHistory: history,
          isLoadingHistory: false,
        );
      });

      if (state.hasError) {
        ref.read(translatorLoadingProvider.notifier).setHistoryError(state.error.toString());
      }
    } finally {
      ref.read(translatorLoadingProvider.notifier).setLoadingHistory(false);
    }
  }

  /// Add result to history
  Future<void> addToHistory(TranslationResultEntity result) async {
    final current = state.value ?? const TranslatorOutputState();
    state = await AsyncValue.guard(() async {
      final updatedHistory = [result, ...current.translationHistory];
      return current.copyWith(translationHistory: updatedHistory);
    });
  }

  /// Remove result from history
  Future<void> removeFromHistory(String resultId) async {
    final current = state.value ?? const TranslatorOutputState();
    state = await AsyncValue.guard(() async {
      final updatedHistory = current.translationHistory
          .where((result) => result.id != resultId)
          .toList();
      return current.copyWith(translationHistory: updatedHistory);
    });
  }

  /// Clear translation history
  Future<void> clearHistory() async {
    final current = state.value ?? const TranslatorOutputState();
    state = await AsyncValue.guard(() async {
      return current.copyWith(translationHistory: []);
    });
  }

  /// Get translation by ID from history
  TranslationResultEntity? getTranslationById(String id) {
    return state.value?.translationHistory.where((result) => result.id == id).firstOrNull;
  }

  /// Get recent translations (last N)
  List<TranslationResultEntity> getRecentTranslations({int count = 10}) {
    return state.value?.translationHistory.take(count).toList() ?? [];
  }

  /// Search history by language
  List<TranslationResultEntity> searchHistoryByLanguage(String language) {
    return state.value?.translationHistory
        .where((result) => result.language.toLowerCase() == language.toLowerCase())
        .toList() ?? [];
  }

  /// Search history by content
  List<TranslationResultEntity> searchHistoryByContent(String query) {
    final lowerQuery = query.toLowerCase();
    return state.value?.translationHistory
        .where((result) =>
            result.translatedCode.toLowerCase().contains(lowerQuery) ||
            (result.metadata?.toString().toLowerCase().contains(lowerQuery) ?? false))
        .toList() ?? [];
  }

  /// Set error
  Future<void> setError(String error) async {
    state = await AsyncValue.guard(() async {
      return state.value!.copyWith(error: error);
    });
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
      return const TranslatorOutputState();
    });
  }

  /// Placeholder method for getting translation history
  /// In a real implementation, this would use a use case
  Future<List<TranslationResultEntity>> _getTranslationHistory() async {
    // Retrieve the repository using the provider reference
    final repository = ref.read(translatorRepositoryProvider);
    // Use the repository to get the translation history
    return await repository.getTranslationHistory();
  }
}

// Provider for translator output
final translatorOutputProvider = AsyncNotifierProvider<TranslatorOutputNotifier, TranslatorOutputState>(
  () => TranslatorOutputNotifier(),
);

// Computed provider for current translation result
final currentTranslationResultProvider = Provider<TranslationResultEntity?>((ref) {
  return ref.watch(translatorOutputProvider).maybeWhen(
    data: (state) => state.currentResult,
    orElse: () => null,
  );
});

// Computed provider for translation history
final translationHistoryProvider = Provider<List<TranslationResultEntity>>((ref) {
  return ref.watch(translatorOutputProvider).maybeWhen(
    data: (state) => state.translationHistory,
    orElse: () => [],
  );
});

// Computed provider for history loading state
final isLoadingTranslationHistoryProvider = Provider<bool>((ref) {
  return ref.watch(translatorOutputProvider).maybeWhen(
    data: (state) => state.isLoadingHistory,
    orElse: () => false,
  );
});

// Computed provider for output error
final translatorOutputErrorProvider = Provider<String?>((ref) {
  return ref.watch(translatorOutputProvider).maybeWhen(
    data: (state) => state.error,
    orElse: () => null,
  );
});
