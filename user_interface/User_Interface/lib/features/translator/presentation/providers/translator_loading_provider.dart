import 'package:flutter_riverpod/flutter_riverpod.dart';

// Loading state for translator operations
class TranslatorLoadingState {
  const TranslatorLoadingState({
    this.isTranslating = false,
    this.isLoadingConfig = false,
    this.isLoadingHistory = false,
    this.progress = 0.0,
    this.error,
  });

  final bool isTranslating;
  final bool isLoadingConfig;
  final bool isLoadingHistory;
  final double progress;
  final String? error;

  bool get isLoading => isTranslating || isLoadingConfig || isLoadingHistory;

  TranslatorLoadingState copyWith({
    bool? isTranslating,
    bool? isLoadingConfig,
    bool? isLoadingHistory,
    double? progress,
    String? error,
  }) {
    return TranslatorLoadingState(
      isTranslating: isTranslating ?? this.isTranslating,
      isLoadingConfig: isLoadingConfig ?? this.isLoadingConfig,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

// State notifier for translator loading states
class TranslatorLoadingNotifier extends Notifier<TranslatorLoadingState> {
  @override
  TranslatorLoadingState build() {
    return const TranslatorLoadingState();
  }

  /// Set translating state
  void setTranslating(bool isTranslating) {
    state = state.copyWith(
      isTranslating: isTranslating,
      error: isTranslating ? null : state.error,
    );
  }

  /// Set loading config state
  void setLoadingConfig(bool isLoadingConfig) {
    state = state.copyWith(
      isLoadingConfig: isLoadingConfig,
      error: isLoadingConfig ? null : state.error,
    );
  }

  /// Set loading history state
  void setLoadingHistory(bool isLoadingHistory) {
    state = state.copyWith(
      isLoadingHistory: isLoadingHistory,
      error: isLoadingHistory ? null : state.error,
    );
  }

  /// Update progress
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress.clamp(0.0, 1.0));
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset all loading states
  void reset() {
    state = const TranslatorLoadingState();
  }

  /// Set error for translation
  void setTranslationError(String error) {
    state = state.copyWith(
      isTranslating: false,
      error: error,
    );
  }

  /// Set error for config loading
  void setConfigError(String error) {
    state = state.copyWith(
      isLoadingConfig: false,
      error: error,
    );
  }

  /// Set error for history loading
  void setHistoryError(String error) {
    state = state.copyWith(
      isLoadingHistory: false,
      error: error,
    );
  }
}

// Provider for translator loading state
final translatorLoadingProvider =
    NotifierProvider<TranslatorLoadingNotifier, TranslatorLoadingState>(
  () => TranslatorLoadingNotifier(),
);

// Computed provider for translation loading state
final isTranslatingProvider = Provider<bool>((ref) {
  return ref.watch(translatorLoadingProvider).isTranslating;
});

// Computed provider for config loading state
final isLoadingConfigProvider = Provider<bool>((ref) {
  return ref.watch(translatorLoadingProvider).isLoadingConfig;
});

// Computed provider for history loading state
final isLoadingHistoryProvider = Provider<bool>((ref) {
  return ref.watch(translatorLoadingProvider).isLoadingHistory;
});

// Computed provider for overall loading state
final isTranslatorLoadingProvider = Provider<bool>((ref) {
  return ref.watch(translatorLoadingProvider).isLoading;
});

// Computed provider for loading progress
final translationProgressProvider = Provider<double>((ref) {
  return ref.watch(translatorLoadingProvider).progress;
});

// Computed provider for loading error
final translatorLoadingErrorProvider = Provider<String?>((ref) {
  return ref.watch(translatorLoadingProvider).error;
});
