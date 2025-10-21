import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/translator_input_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    // Listen for changes in the provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPseudocode = ref.read(translatorInputProvider).pseudocode;
      if (_textController.text != currentPseudocode) {
        _textController.text = currentPseudocode;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    ref.read(translatorInputProvider.notifier).updatePseudocode(text);

    // Update cursor position
    ref.read(translatorInputProvider.notifier).updateCursorPosition(
          _textController.selection.baseOffset,
        );
  }

  void _onSelectionChanged() {
    ref.read(translatorInputProvider.notifier).updateCursorPosition(
          _textController.selection.baseOffset,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputState = ref.watch(translatorInputProvider);

    // Update text when provider state changes
    if (_textController.text != inputState.pseudocode) {
      _textController.text = inputState.pseudocode;
      _textController.selection = TextSelection.collapsed(
        offset: inputState.cursorPosition,
      );
    }

    return Column(
      children: [
        // Toolbar
        _buildToolbar(),

        // Editor
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('translator_input_field'),
              controller: _textController,
              focusNode: _focusNode,
              scrollController: _scrollController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'JetBrainsMono, monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your pseudocode here...\n\nExample:\n'
                    'FUNCTION add_numbers(a, b)\n'
                    '    RETURN a + b\n'
                    'END FUNCTION\n\n'
                    'add_numbers(5, 3)',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontFamily: 'JetBrainsMono, monospace',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                ref
                    .read(translatorInputProvider.notifier)
                    .updatePseudocode(value);
              },
            ),
          ),
        ),

        // Status bar
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Pseudocode Editor',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: _copyToClipboard,
            tooltip: 'Copy pseudocode',
          ),
          IconButton(
            icon: const Icon(Icons.paste, size: 18),
            onPressed: _pasteFromClipboard,
            tooltip: 'Paste pseudocode',
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: _clearEditor,
            tooltip: 'Clear editor',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final theme = Theme.of(context);
    final inputState = ref.watch(translatorInputProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Lines: ${_getLineCount()} | Characters: ${_getCharacterCount()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          if (inputState.error != null)
            Text(
              inputState.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  int _getLineCount() {
    final text = _textController.text;
    if (text.isEmpty) return 1;
    return text.split('\n').length;
  }

  int _getCharacterCount() {
    return _textController.text.length;
  }

  void _copyToClipboard() {
    final text = _textController.text;
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pseudocode copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final currentText = _textController.text;
      final selection = _textController.selection;

      // Normalize selection indices (handle -1 or invalid values)
      int start = selection.start;
      int end = selection.end;
      if (start < 0 || start > currentText.length) {
        start = 0;
      }
      if (end < 0 || end > currentText.length) {
        end = 0;
      }

      final newText = currentText.replaceRange(
        start,
        end,
        data!.text!,
      );
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: start + data.text!.length,
        ),
      );
    }
  }

  void _clearEditor() {
    _textController.clear();
    ref.read(translatorInputProvider.notifier).clearInput();
  }
}
