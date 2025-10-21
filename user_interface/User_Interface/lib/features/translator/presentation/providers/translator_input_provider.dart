import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/translation_request_entity.dart';
import '../../domain/usecases/translate_pseudocode_use_case.dart';
import 'translator_loading_provider.dart';
import 'translator_output_provider.dart';
import 'translator_repository_provider.dart';

// Provider for translate pseudocode use case
final translatePseudocodeUseCaseProvider =
    Provider<TranslatePseudocodeUseCase>((ref) {
  return TranslatePseudocodeUseCase(ref.watch(translatorRepositoryProvider));
});

// Input state for translator
class TranslatorInputState {
  const TranslatorInputState({
    this.pseudocode = '',
    this.selectedLanguage = 'python',
    this.cursorPosition = 0,
    this.isDirty = false,
    this.error,
  });

  final String pseudocode;
  final String selectedLanguage;
  final int cursorPosition;
  final bool isDirty;
  final String? error;

  bool get isValid => pseudocode.trim().isNotEmpty;

  TranslatorInputState copyWith({
    String? pseudocode,
    String? selectedLanguage,
    int? cursorPosition,
    bool? isDirty,
    String? error,
  }) {
    return TranslatorInputState(
      pseudocode: pseudocode ?? this.pseudocode,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      isDirty: isDirty ?? this.isDirty,
      error: error,
    );
  }
}

// State notifier for translator input
class TranslatorInputNotifier extends Notifier<TranslatorInputState> {
  @override
  TranslatorInputState build() {
    return const TranslatorInputState();
  }

  /// Update pseudocode text
  void updatePseudocode(String pseudocode) {
    state = state.copyWith(
      pseudocode: pseudocode,
      isDirty: true,
      error: null,
    );
  }

  /// Update selected language
  void updateLanguage(String language) {
    state = state.copyWith(
      selectedLanguage: language,
      isDirty: true,
      error: null,
    );
  }

  /// Update cursor position
  void updateCursorPosition(int position) {
    state = state.copyWith(cursorPosition: position);
  }

  /// Clear input
  void clearInput() {
    state = const TranslatorInputState();
  }

  /// Translate current input
  Future<bool> translate() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Pseudocode cannot be empty');
      return false;
    }

    // Clear any previous loading error and set loading state
    ref.read(translatorLoadingProvider.notifier).clearError();
    ref.read(translatorLoadingProvider.notifier).setTranslating(true);

    try {
      // Create translation request
      final request = TranslationRequestEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pseudocode: state.pseudocode.trim(),
        targetLanguage: state.selectedLanguage,
      );

      // Execute translation
      final useCase = ref.read(translatePseudocodeUseCaseProvider);
      final result = await useCase(request);

      // Update output provider with result
      await ref
          .read(translatorOutputProvider.notifier)
          .setTranslationResult(result);

      // Clear dirty state
      state = state.copyWith(isDirty: false);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Translation failed: ${e.toString()}');
      // Surface error in loading state for inline progress banner
      ref
          .read(translatorLoadingProvider.notifier)
          .setTranslationError(e.toString());
      return false;
    } finally {
      ref.read(translatorLoadingProvider.notifier).setTranslating(false);
    }
  }

  /// Load pseudocode from string
  void loadPseudocode(String pseudocode) {
    state = state.copyWith(
      pseudocode: pseudocode,
      isDirty: false,
      error: null,
    );
  }

  /// Reset state
  void reset() {
    state = const TranslatorInputState();
  }
}

// Provider for translator input
final translatorInputProvider =
    NotifierProvider<TranslatorInputNotifier, TranslatorInputState>(
  () => TranslatorInputNotifier(),
);

// Computed provider for current pseudocode
final currentPseudocodeProvider = Provider<String>((ref) {
  return ref.watch(translatorInputProvider).pseudocode;
});

// Computed provider for selected language
final selectedLanguageProvider = Provider<String>((ref) {
  return ref.watch(translatorInputProvider).selectedLanguage;
});

// Computed provider for input validity
final isInputValidProvider = Provider<bool>((ref) {
  return ref.watch(translatorInputProvider).isValid;
});
