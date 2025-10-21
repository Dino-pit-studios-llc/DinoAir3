import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'translation_download_html_stub.dart' if (dart.library.html) 'dart:html'
    as html;

// Conditional import for platform-specific translation output helpers

import '../../domain/translation_result_entity.dart';

class TranslationOutputWidget extends ConsumerStatefulWidget {
  const TranslationOutputWidget({
    super.key,
    required this.result,
  });

  final TranslationResultEntity result;

  @override
  ConsumerState<TranslationOutputWidget> createState() =>
      _TranslationOutputWidgetState();
}

class _TranslationOutputWidgetState
    extends ConsumerState<TranslationOutputWidget> {
  final _scrollController = ScrollController();
  bool _isExpanded = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('translation_output_panel'),
      children: [
        // Header
        _buildHeader(),

        // Content
        Expanded(
          child:
              _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Language badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.result.language.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Confidence score
          if (widget.result.confidence > 0)
            Row(
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: _getConfidenceColor(widget.result.confidence),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(widget.result.confidence * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getConfidenceColor(widget.result.confidence),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          const Spacer(),

          // Actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: _copyToClipboard,
                tooltip: 'Copy translated code',
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 18),
                onPressed: _downloadCode,
                tooltip: 'Download as file',
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                onPressed: _toggleExpanded,
                tooltip: _isExpanded ? 'Collapse' : 'Expand',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code display
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    widget.result.translatedCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontFamilyFallback: const ['monospace'],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Metadata
          _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview text
          Expanded(
            child: Text(
              _getPreviewText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontFamily: 'JetBrainsMono',
                fontFamilyFallback: const ['monospace'],
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Metadata (collapsed)
          _buildMetadata(collapsed: true),
        ],
      ),
    );
  }

  Widget _buildMetadata({bool collapsed = false}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Translation Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (collapsed)
            Text(
              'Language: ${widget.result.language} | Confidence: ${(widget.result.confidence * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Text(
                      'Language:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      widget.result.language.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Text(
                      'Confidence:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${(widget.result.confidence * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _getConfidenceColor(widget.result.confidence),
                      ),
                    ),
                  ],
                ),
                if (widget.result.metadata != null) ...[
                  TableRow(
                    children: [
                      Text(
                        'Model:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        widget.result.metadata!['model'] ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(
                        'Tokens:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${widget.result.metadata!['tokens'] ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
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

  String _getPreviewText() {
    final lines = widget.result.translatedCode.split('\n');
    if (lines.length <= 8) {
      return widget.result.translatedCode;
    }
    return lines.take(8).join('\n') + '\n...';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.result.translatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Translated code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadCode() {
    final output = widget.result.translatedCode;
    if (output.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to download'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (kIsWeb) {
      try {
        final language = widget.result.language.toLowerCase();
        String two(int n) => n.toString().padLeft(2, '0');
        final now = DateTime.now();
        final timestamp =
            '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
        final filename = 'translation_${language}_$timestamp.txt';

        final blob = html.Blob([output], 'text/plain');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)..download = filename;
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start download'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download is only available on web builds'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}

// Widget for displaying translation results in a list
class TranslationResultCard extends ConsumerWidget {
  const TranslationResultCard({
    super.key,
    required this.result,
    this.onTap,
  });

  final TranslationResultEntity result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.language.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(result.confidence * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getConfidenceColor(result.confidence),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Code preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPreviewText(result.translatedCode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontFamilyFallback: const ['monospace'],
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 12),

              // Metadata
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(
                        result.metadata?['timestamp'] ?? DateTime.now()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _getPreviewText(String code) {
    final lines = code.split('\n');
    if (lines.length <= 4) {
      return code;
    }
    return lines.take(4).join('\n') + '\n...';
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp is DateTime) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }
}
