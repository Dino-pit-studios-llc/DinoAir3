import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class for chat input
class ChatInputState {
  const ChatInputState({
    this.text = '',
    this.isEnabled = true,
    this.isSending = false,
    this.showAttachmentButton = false,
  });

  final String text;
  final bool isEnabled;
  final bool isSending;
  final bool showAttachmentButton;

  ChatInputState copyWith({
    String? text,
    bool? isEnabled,
    bool? isSending,
    bool? showAttachmentButton,
  }) {
    return ChatInputState(
      text: text ?? this.text,
      isEnabled: isEnabled ?? this.isEnabled,
      isSending: isSending ?? this.isSending,
      showAttachmentButton: showAttachmentButton ?? this.showAttachmentButton,
    );
  }

  bool get canSend => text.trim().isNotEmpty && isEnabled && !isSending;
}

// State notifier for chat input management
class ChatInputNotifier extends Notifier<ChatInputState> {
  final TextEditingController _textController = TextEditingController();

  TextEditingController get textController => _textController;

  @override
  ChatInputState build() {
    return const ChatInputState();
  }

  /// Update the input text
  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  /// Clear the input text
  void clearText() {
    _textController.clear();
    state = state.copyWith(text: '');
  }

  /// Set sending state
  void setSending(bool isSending) {
    state = state.copyWith(isSending: isSending, isEnabled: !isSending);
  }

  /// Set enabled state
  void setEnabled(bool isEnabled) {
    state = state.copyWith(isEnabled: isEnabled);
  }

  /// Set attachment button visibility
  void setShowAttachmentButton(bool show) {
    state = state.copyWith(showAttachmentButton: show);
  }

  /// Append text to current input (useful for quick inserts)
  void appendText(String text) {
    final newText = state.text + text;
    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
    state = state.copyWith(text: newText);
  }

  /// Insert text at cursor position
  void insertTextAtCursor(String text) {
    final currentPosition = _textController.selection.start;
    final newText = state.text.substring(0, currentPosition) +
        text +
        state.text.substring(currentPosition);
    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: currentPosition + text.length),
    );
    state = state.copyWith(text: newText);
  }

  /// Focus the text field
  void focusTextField() {
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  /// Get current text and clear input
  String getTextAndClear() {
    final text = state.text;
    clearText();
    return text;
  }

  /// Reset input state
  void reset() {
    _textController.clear();
    state = const ChatInputState();
  }

  /// Set maximum text length
  static const int maxLength = 4000;

  /// Check if text is at maximum length
  bool get isAtMaxLength => state.text.length >= maxLength;

  /// Get remaining characters
  int get remainingCharacters => maxLength - state.text.length;
}

// Provider for chat input state
final chatInputProvider =
    NotifierProvider<ChatInputNotifier, ChatInputState>(
  () => ChatInputNotifier(),
);

// Provider for input text (computed)
final chatInputTextProvider = Provider<String>((ref) {
  return ref.watch(chatInputProvider).text;
});

// Provider for send button enabled state (computed)
final chatInputCanSendProvider = Provider<bool>((ref) {
  final state = ref.watch(chatInputProvider);
  return state.canSend;
});

// Provider for character count (computed)
final chatInputCharacterCountProvider = Provider<int>((ref) {
  return ref.watch(chatInputProvider).text.length;
});

// Provider for remaining characters (computed)
final chatInputRemainingCharactersProvider = Provider<int>((ref) {
  return ChatInputNotifier.maxLength - ref.watch(chatInputProvider).text.length;
});
