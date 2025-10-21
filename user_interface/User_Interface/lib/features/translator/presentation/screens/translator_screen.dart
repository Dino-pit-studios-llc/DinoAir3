import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/translator_config_provider.dart';
import '../providers/translator_input_provider.dart';
import '../providers/translator_loading_provider.dart';
import '../providers/translator_output_provider.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/language_selector_widget.dart';
import '../widgets/translation_history_widget.dart';
import '../widgets/translation_output_widget.dart';
import '../widgets/translation_progress_widget.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _splitViewController = SplitViewController();

  @override
  void initState() {
    super.initState();
    // Load initial configuration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(translatorConfigProvider.notifier).loadConfig();
      ref.read(translatorConfigProvider.notifier).loadSupportedLanguages();
    });
  }

  @override
  void dispose() {
    _splitViewController.dispose();
    super.dispose();
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const TranslatorSettingsDialog(),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TranslationHistoryWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTranslating = ref.watch(isTranslatingProvider);
    final currentResult = ref.watch(currentTranslationResultProvider);
    final isInputValid = ref.watch(isInputValidProvider);
    final theme = Theme.of(context);

    final isFabDisabled = isTranslating || !isInputValid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pseudocode Translator'),
        actions: [
          // Language selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: const LanguageSelectorWidget(),
          ),

          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Translator settings',
          ),

          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
            tooltip: 'Translation history',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (isTranslating) const TranslationProgressWidget(),

          // Split view for input and output
          Expanded(
            child: SplitView(
              controller: _splitViewController,
              viewMode: SplitViewMode.Horizontal,
              gripColor: theme.colorScheme.outline.withOpacity(0.3),
              gripColorActive: theme.colorScheme.primary,
              gripSize: 8,
              children: [
                // Left panel - Code editor
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const CodeEditorWidget(),
                ),

                // Right panel - Translation output
                Container(
                  child: currentResult != null
                      ? TranslationOutputWidget(result: currentResult)
                      : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Translate',
        child: FloatingActionButton.extended(
          key: const Key('translator_translate_button'),
          onPressed: isFabDisabled ? null : _translate,
          backgroundColor: isFabDisabled ? theme.disabledColor : null,
          foregroundColor: isFabDisabled
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : null,
          icon: isTranslating
              ? Container(
                  width: 16,
                  height: 16,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate),
          label: Text(isTranslating ? 'Translating...' : 'Translate'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter pseudocode to translate',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write your pseudocode in the left panel and click Translate to see the result',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translate() async {
    final success =
        await ref.read(translatorInputProvider.notifier).translate();

    if (!success && mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(translatorInputProvider).error ?? 'Translation failed',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Split view controller for resizable panels
class SplitViewController extends ChangeNotifier {
  double _dividerPosition = 0.5; // 50/50 split by default

  double get dividerPosition => _dividerPosition;

  set dividerPosition(double value) {
    if (_dividerPosition != value) {
      _dividerPosition = value.clamp(0.1, 0.9); // Min 10%, max 90%
      notifyListeners();
    }
  }

  void updateDividerPosition(double delta) {
    dividerPosition = _dividerPosition + delta;
  }
}

// Split view widget for resizable panels
class SplitView extends StatefulWidget {
  const SplitView({
    super.key,
    required this.controller,
    required this.children,
    this.viewMode = SplitViewMode.Horizontal,
    this.gripColor = Colors.grey,
    this.gripColorActive = Colors.blue,
    this.gripSize = 8,
  });

  final SplitViewController controller;
  final List<Widget> children;
  final SplitViewMode viewMode;
  final Color gripColor;
  final Color gripColorActive;
  final double gripSize;

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length != 2) {
      throw ArgumentError('SplitView requires exactly 2 children');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isHorizontal = widget.viewMode == SplitViewMode.Horizontal;

        final totalSize =
            isHorizontal ? constraints.maxWidth : constraints.maxHeight;

        final firstSize = totalSize * widget.controller.dividerPosition;
        final secondSize = totalSize - firstSize;

        return Stack(
          children: [
            // First child
            Positioned(
              left: isHorizontal ? 0 : null,
              top: isHorizontal ? 0 : 0,
              right: isHorizontal ? null : 0,
              bottom: isHorizontal ? 0 : null,
              width: isHorizontal ? firstSize : null,
              height: isHorizontal ? null : firstSize,
              child: widget.children[0],
            ),

            // Divider
            Positioned(
              left: isHorizontal ? firstSize : null,
              top: isHorizontal ? 0 : firstSize,
              right: isHorizontal ? null : 0,
              bottom: isHorizontal ? 0 : null,
              width: isHorizontal ? widget.gripSize : null,
              height: isHorizontal ? null : widget.gripSize,
              child: MouseRegion(
                cursor: isHorizontal
                    ? SystemMouseCursors.resizeColumn
                    : SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onHorizontalDragStart: isHorizontal ? _onDragStart : null,
                  onVerticalDragStart: isHorizontal ? null : _onDragStart,
                  onHorizontalDragUpdate: isHorizontal ? _onDragUpdate : null,
                  onVerticalDragUpdate: isHorizontal ? null : _onDragUpdate,
                  onHorizontalDragEnd: isHorizontal ? _onDragEnd : null,
                  onVerticalDragEnd: isHorizontal ? null : _onDragEnd,
                  child: Container(
                    color:
                        _isDragging ? widget.gripColorActive : widget.gripColor,
                    child: Center(
                      child: Container(
                        width: isHorizontal ? 2 : null,
                        height: isHorizontal ? null : 2,
                        decoration: BoxDecoration(
                          color: _isDragging
                              ? widget.gripColorActive
                              : widget.gripColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Second child
            Positioned(
              left: isHorizontal ? firstSize + widget.gripSize : 0,
              top: isHorizontal ? 0 : firstSize + widget.gripSize,
              right: isHorizontal ? 0 : 0,
              bottom: isHorizontal ? 0 : 0,
              child: widget.children[1],
            ),
          ],
        );
      },
    );
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final isHorizontal = widget.viewMode == SplitViewMode.Horizontal;
    final delta = isHorizontal
        ? details.delta.dx / context.size!.width
        : details.delta.dy / context.size!.height;

    widget.controller.updateDividerPosition(delta);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }
}

enum SplitViewMode {
  Horizontal,
  Vertical,
}

// Placeholder dialogs for settings and history
class TranslatorSettingsDialog extends StatelessWidget {
  const TranslatorSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Translator Settings'),
      content: const Text('Settings dialog - to be implemented'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
