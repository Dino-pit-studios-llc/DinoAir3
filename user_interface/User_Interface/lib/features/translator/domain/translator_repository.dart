import 'dart:async';

import 'translation_request_entity.dart';
import 'translation_result_entity.dart';
import 'translator_config_entity.dart';

/// Repository interface for pseudocode translation operations.
///
/// This repository defines the contract for AI-powered translation of pseudocode
/// to various programming languages. It supports both request/response and
/// streaming translation modes.
///
/// ## Responsibilities
/// - Translate pseudocode to target programming languages
/// - Manage translator configuration (model, temperature, etc.)
/// - Provide supported language information
/// - Handle translation history caching
/// - Support streaming translations for large responses
///
/// ## Supported Languages
/// The translator supports multiple programming languages including:
/// - Python, JavaScript, TypeScript, Java, C++, C#, Go, Rust, Swift, Kotlin
/// - Ruby, PHP, Dart, Scala, R, SQL, HTML/CSS
///
/// ## Usage Example
/// ```dart
/// class TranslatePseudocodeUseCase {
///   final TranslatorRepository repository;
///
///   const TranslatePseudocodeUseCase(this.repository);
///
///   Future<TranslationResultEntity> call(TranslationRequestEntity request) {
///     return repository.translatePseudocode(request);
///   }
/// }
/// ```
///
/// ## Streaming Example
/// ```dart
/// final request = TranslationRequestEntity(
///   pseudocode: 'for each item in list, print item',
///   targetLanguage: 'python',
/// );
///
/// final stream = repository.translateWithStreaming(request);
/// await for (final chunk in stream!) {
///   print('Received: ${chunk.translatedCode}');
/// }
/// ```
///
/// ## Error Handling
/// Operations may throw:
/// - `ServerException`: AI model or backend errors
/// - `NetworkException`: Network connectivity issues
/// - `ValidationException`: Invalid request parameters
/// - `RateLimitException`: API rate limit exceeded
///
/// ## Implementation Notes
/// Implementations should:
/// - Validate input pseudocode and target language
/// - Handle AI model failures gracefully
/// - Cache translations locally when possible
/// - Support offline mode with cached history
/// - Implement streaming for better UX on large translations
///
/// See also:
/// - [TranslationRequestEntity]: Request parameters
/// - [TranslationResultEntity]: Translation response
/// - [TranslatorConfigEntity]: Configuration settings
abstract class TranslatorRepository {
  /// Translates pseudocode to the target programming language.
  ///
  /// Sends the pseudocode to an AI model (e.g., GPT-4, Claude) for translation.
  /// The translation includes code, explanation, and confidence score.
  ///
  /// Parameters:
  /// - [request]: Translation request with pseudocode and target language
  ///
  /// Returns a translation result with generated code and metadata.
  ///
  /// Example:
  /// ```dart
  /// final request = TranslationRequestEntity(
  ///   pseudocode: '''
  ///     function calculateTotal:
  ///       sum = 0
  ///       for each number in numbers:
  ///         sum = sum + number
  ///       return sum
  ///   ''',
  ///   targetLanguage: 'python',
  ///   includeComments: true,
  /// );
  ///
  /// final result = await repository.translatePseudocode(request);
  /// print('Translation:\n${result.translatedCode}');
  /// print('Confidence: ${result.confidence}%');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if pseudocode is empty or language unsupported
  /// - [RateLimitException] if API rate limit exceeded
  /// - [ServerException] if AI model fails or backend error
  /// - [NetworkException] if network request fails
  Future<TranslationResultEntity> translatePseudocode(
      TranslationRequestEntity request);

  /// Retrieves list of supported target programming languages.
  ///
  /// Returns language identifiers that can be used in [TranslationRequestEntity].
  ///
  /// Returns a list of language codes (e.g., ['python', 'javascript', 'java']).
  ///
  /// Example:
  /// ```dart
  /// final languages = await repository.getSupportedLanguages();
  /// print('Supported: ${languages.join(', ')}');
  ///
  /// // Use in dropdown
  /// DropdownButton<String>(
  ///   items: languages.map((lang) =>
  ///     DropdownMenuItem(value: lang, child: Text(lang))
  ///   ).toList(),
  /// );
  /// ```
  ///
  /// Throws:
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<String>> getSupportedLanguages();

  /// Retrieves current translator configuration settings.
  ///
  /// Returns configuration including AI model, temperature, max tokens, etc.
  ///
  /// Example:
  /// ```dart
  /// final config = await repository.getTranslatorConfig();
  /// print('Model: ${config.model}');
  /// print('Temperature: ${config.temperature}');
  /// print('Max tokens: ${config.maxTokens}');
  /// ```
  ///
  /// Throws:
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<TranslatorConfigEntity> getTranslatorConfig();

  /// Updates translator configuration settings.
  ///
  /// Allows changing AI model, temperature, max tokens, and other settings.
  /// Settings are persisted and used for subsequent translations.
  ///
  /// Parameters:
  /// - [config]: New configuration settings to apply
  ///
  /// Example:
  /// ```dart
  /// final newConfig = TranslatorConfigEntity(
  ///   model: 'gpt-4',
  ///   temperature: 0.7,
  ///   maxTokens: 2000,
  ///   includeComments: true,
  ///   includeTypeHints: true,
  /// );
  ///
  /// await repository.updateTranslatorConfig(newConfig);
  /// print('Configuration updated');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if config values are invalid
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<void> updateTranslatorConfig(TranslatorConfigEntity config);

  /// Translates pseudocode with streaming response.
  ///
  /// Similar to [translatePseudocode] but returns a stream of partial results
  /// as the AI model generates the translation. Useful for better UX on
  /// large translations.
  ///
  /// Parameters:
  /// - [request]: Translation request with pseudocode and target language
  ///
  /// Returns a stream of translation chunks, or null if streaming not supported.
  /// Each chunk contains incrementally generated code.
  ///
  /// Example:
  /// ```dart
  /// final request = TranslationRequestEntity(
  ///   pseudocode: 'sort list in ascending order',
  ///   targetLanguage: 'python',
  /// );
  ///
  /// final stream = repository.translateWithStreaming(request);
  /// if (stream != null) {
  ///   String fullCode = '';
  ///   await for (final chunk in stream) {
  ///     fullCode += chunk.translatedCode;
  ///     print('Current: $fullCode'); // Show partial result
  ///   }
  /// } else {
  ///   // Fallback to non-streaming
  ///   final result = await repository.translatePseudocode(request);
  /// }
  /// ```
  ///
  /// Returns `null` if:
  /// - Backend doesn't support streaming
  /// - Selected AI model doesn't support streaming
  /// - Configuration has streaming disabled
  ///
  /// Throws:
  /// - [ValidationException] if request is invalid
  /// - [ServerException] if AI model fails
  /// - [NetworkException] if network fails during streaming
  Stream<TranslationResultEntity>? translateWithStreaming(
      TranslationRequestEntity request);

  /// Retrieves cached translation history from local storage.
  ///
  /// Returns previously completed translations for offline access and
  /// quick reference. Useful for showing recent translations without
  /// network requests.
  ///
  /// Returns a list of past translation results, sorted by timestamp (newest first).
  /// Returns empty list if no history exists.
  ///
  /// Example:
  /// ```dart
  /// final history = await repository.getTranslationHistory();
  /// print('Found ${history.length} past translations');
  ///
  /// for (final past in history.take(5)) {
  ///   print('${past.timestamp}: ${past.targetLanguage}');
  /// }
  ///
  /// // Show in UI for quick access
  /// ListView.builder(
  ///   itemCount: history.length,
  ///   itemBuilder: (context, index) {
  ///     final translation = history[index];
  ///     return ListTile(
  ///       title: Text(translation.targetLanguage),
  ///       subtitle: Text(translation.pseudocode),
  ///       onTap: () => reuseTranslation(translation),
  ///     );
  ///   },
  /// );
  /// ```
  ///
  /// Implementation Notes:
  /// - History is stored locally (no network request)
  /// - Best-effort: may return empty if cache unavailable
  /// - Consider limiting history size (e.g., last 50 translations)
  ///
  /// Throws:
  /// - Generally doesn't throw; returns empty list on errors
  Future<List<TranslationResultEntity>> getTranslationHistory();
}
