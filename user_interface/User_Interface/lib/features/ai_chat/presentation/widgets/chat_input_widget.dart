import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_input_provider.dart';

class ChatInputWidget extends ConsumerStatefulWidget {
  const ChatInputWidget({
    required this.onSendMessage,
    this.enabled = true,
    super.key,
  });

  final Function(String) onSendMessage;
  final bool enabled;

  @override
  ConsumerState<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends ConsumerState<ChatInputWidget> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = ref.read(chatInputProvider.notifier).textController;
    _focusNode = FocusNode();

    // Listen to text changes
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(chatInputProvider.notifier).updateText(_textController.text);
  }

  void _handleSend() {
    final text = _textController.text.trim();
    // Ensure keyboard Enter sends respect the same canSend guard as the button
    final canSend = ref.read(chatInputCanSendProvider);
    if (text.isNotEmpty && widget.enabled && canSend) {
      assert(() {
        final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        debugPrint('ChatInputWidget: sending "$preview" | Primary focus=${FocusManager.instance.primaryFocus}');
        return true;
      }());
      widget.onSendMessage(text);
      // Clear input after sending to prevent accidental duplicate sends and keep character counter accurate.
      _textController.clear();
      // Keep focus on the input for continued typing (desktop). On mobile, this retains the soft keyboard.
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputState = ref.watch(chatInputProvider);
    final canSend = ref.watch(chatInputCanSendProvider);
    final characterCount = ref.watch(chatInputCharacterCountProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character count indicator
          if (characterCount > 0) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${ChatInputNotifier.maxLength - characterCount} characters remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input field and send button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button (placeholder for future)
              if (inputState.showAttachmentButton) ...[
                IconButton(
                  onPressed: widget.enabled ? () {} : null,
                  icon: Icon(
                    Icons.attach_file,
                    color: widget.enabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  tooltip: 'Attach file',
                ),
                const SizedBox(width: 4),
              ],

              // Text input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Shortcuts(
                    shortcuts: <ShortcutActivator, Intent>{
                      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
                      const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
                    },
                    child: Actions(
                      actions: <Type, Action<Intent>>{
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (intent) {
                            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                            assert(() {
                              debugPrint('ChatInputWidget: Enter pressed. Shift=$isShiftPressed, key=Enter/NumpadEnter');
                              return true;
                            }());
                            if (isShiftPressed) {
                              // Shift+Enter inserts a newline at the current cursor position.
                              final selection = _textController.selection;
                              final insertionOffset = selection.isValid
                                  ? selection.baseOffset.clamp(0, _textController.text.length)
                                  : _textController.text.length;
                              final newText = _textController.text.replaceRange(
                                insertionOffset,
                                insertionOffset,
                                '\n',
                              );
                              _textController.text = newText;
                              _textController.selection =
                                  TextSelection.collapsed(offset: insertionOffset + 1);
                            } else {
                              // Enter sends the message.
                              _handleSend();
                            }
                            return null;
                          },
                        ),
                      },
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _textController,
                        enabled: widget.enabled,
                        maxLength: ChatInputNotifier.maxLength,
                        maxLines: null, // Allow multiple lines
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          counterText: '', // Hide default counter
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: canSend && widget.enabled ? _handleSend : null,
                  icon: inputState.isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              canSend && widget.enabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: canSend && widget.enabled
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: canSend && widget.enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  tooltip: inputState.isSending ? 'Sending...' : 'Send message',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
