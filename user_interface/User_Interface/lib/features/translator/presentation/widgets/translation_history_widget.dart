import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/translation_result_entity.dart';
import '../providers/translator_config_provider.dart';
import '../providers/translator_output_provider.dart';
import 'translation_output_widget.dart';

class TranslationHistoryWidget extends ConsumerStatefulWidget {
  const TranslationHistoryWidget({super.key});

  @override
  ConsumerState<TranslationHistoryWidget> createState() =>
      _TranslationHistoryWidgetState();
}

class _TranslationHistoryWidgetState
    extends ConsumerState<TranslationHistoryWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterLanguage = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Load history on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(translatorOutputProvider.notifier).loadTranslationHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(translatorOutputProvider);
    final isLoadingHistory = ref.watch(isLoadingTranslationHistoryProvider);

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Translation History'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _showClearHistoryDialog,
                tooltip: 'Clear history',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and filter bar
              _buildSearchBar(),

              // Content
              Expanded(
                child: historyAsync.when(
                  data: (state) => _buildHistoryList(state.translationHistory),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load history',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(translatorOutputProvider.notifier)
                                .loadTranslationHistory(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search translations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter row
          Row(
            children: [
              Text(
                'Filter by language:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _filterLanguage,
                  isExpanded: true,
                  items: ['All', ...availableLanguages]
                      .map<DropdownMenuItem<String>>((language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language == 'All'
                          ? 'All languages'
                          : _getLanguageDisplayName(language)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterLanguage = value ?? 'All';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<TranslationResultEntity> history) {
    final filteredHistory = _getFilteredHistory(history);

    if (filteredHistory.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final result = filteredHistory[index];
        return TranslationResultCard(
          result: result,
          onTap: () => _showTranslationDetail(result),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterLanguage != 'All'
                ? 'No translations found'
                : 'No translation history',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterLanguage != 'All'
                ? 'Try adjusting your search or filter criteria'
                : 'Your translation history will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<TranslationResultEntity> _getFilteredHistory(
      List<TranslationResultEntity> history) {
    return history.where((result) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!result.translatedCode.toLowerCase().contains(query) &&
            !result.language.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filter by language
      if (_filterLanguage != 'All' && result.language != _filterLanguage) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getLanguageDisplayName(String language) {
    const languageNames = {
      'python': 'Python',
      'javascript': 'JavaScript',
      'java': 'Java',
      'cpp': 'C++',
      'csharp': 'C#',
      'go': 'Go',
      'rust': 'Rust',
      'php': 'PHP',
      'ruby': 'Ruby',
      'swift': 'Swift',
      'kotlin': 'Kotlin',
      'typescript': 'TypeScript',
      'scala': 'Scala',
      'dart': 'Dart',
    };

    return languageNames[language] ?? language.toUpperCase();
  }

  void _showTranslationDetail(TranslationResultEntity result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Translation to ${result.language.toUpperCase()}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    // Copy to clipboard
                    await Clipboard.setData(
                        ClipboardData(text: result.translatedCode));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                  tooltip: 'Copy translation',
                ),
              ],
            ),
            body: TranslationOutputWidget(result: result),
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all translation history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(translatorOutputProvider.notifier).clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// Compact history item for lists
class CompactHistoryItem extends ConsumerWidget {
  const CompactHistoryItem({
    super.key,
    required this.result,
    this.onTap,
    this.onDelete,
  });

  final TranslationResultEntity result;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            result.language.substring(0, 2).toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      title: Text(
        _getPreviewText(result.translatedCode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Row(
        children: [
          Text(
            result.language.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(result.confidence * 100).toInt()}% confidence',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getConfidenceColor(result.confidence),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () async {
              // Copy to clipboard
              await Clipboard.setData(
                  ClipboardData(text: result.translatedCode));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            tooltip: 'Copy',
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _getPreviewText(String code) {
    final lines = code.split('\n');
    if (lines.length <= 2) {
      return code;
    }
    return lines.take(2).join('\n') + '...';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

// History statistics widget
class HistoryStatsWidget extends ConsumerWidget {
  const HistoryStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(translationHistoryProvider);

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalTranslations = history.length;
    final languageStats = _calculateLanguageStats(history);
    final avgConfidence = _calculateAverageConfidence(history);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: _buildStatItem(
              theme,
              'Total',
              totalTranslations.toString(),
              Icons.translate,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              'Avg Confidence',
              '${(avgConfidence * 100).toInt()}%',
              Icons.verified,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              'Languages',
              languageStats.length.toString(),
              Icons.language,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Map<String, int> _calculateLanguageStats(
      List<TranslationResultEntity> history) {
    final stats = <String, int>{};
    for (final result in history) {
      stats[result.language] = (stats[result.language] ?? 0) + 1;
    }
    return stats;
  }

  double _calculateAverageConfidence(List<TranslationResultEntity> history) {
    if (history.isEmpty) return 0.0;
    final sum = history.map((r) => r.confidence).reduce((a, b) => a + b);
    return sum / history.length;
  }
}
