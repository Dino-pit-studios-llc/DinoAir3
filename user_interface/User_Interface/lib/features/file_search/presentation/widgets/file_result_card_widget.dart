import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/file_search_result.dart';

/// Widget that displays a single file search result as a card
class FileResultCardWidget extends ConsumerWidget {
  final FileSearchResult result;

  const FileResultCardWidget({
    required this.result,
    super.key,
  });

  Future<void> _openFile(BuildContext context) async {
    final uri = Uri.file(result.filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: result.filePath));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Path copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getFileTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (result.isCodeFile) {
      return colorScheme.primary;
    } else if (result.isDocument) {
      return colorScheme.secondary;
    } else if (result.isConfigFile) {
      return colorScheme.tertiary;
    } else if (result.isImage) {
      return colorScheme.error;
    }
    return colorScheme.surfaceContainerHighest;
  }

  IconData _getFileTypeIcon() {
    if (result.isCodeFile) {
      return Icons.code;
    } else if (result.isDocument) {
      return Icons.description;
    } else if (result.isConfigFile) {
      return Icons.settings;
    } else if (result.isImage) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typeColor = _getFileTypeColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _openFile(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileTypeIcon(),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.fileName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.filePath,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyPath(context),
                    tooltip: 'Copy path',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // File metadata
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MetadataChip(
                    icon: Icons.folder,
                    label: result.fileType,
                  ),
                  _MetadataChip(
                    icon: Icons.storage,
                    label: result.fileSizeFormatted,
                  ),
                  _MetadataChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(result.lastModified),
                  ),
                  _MetadataChip(
                    icon: Icons.star,
                    label:
                        '${(result.relevanceScore * 100).toStringAsFixed(0)}%',
                    color: Colors.amber,
                  ),
                ],
              ),

              // Matched keywords
              if (result.matchedKeywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: result.matchedKeywords
                      .map(
                        (keyword) => Chip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Metadata chip widget
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
