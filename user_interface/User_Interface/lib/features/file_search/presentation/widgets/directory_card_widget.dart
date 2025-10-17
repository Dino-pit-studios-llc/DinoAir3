import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/directory_config.dart';

/// Widget that displays a directory configuration card
class DirectoryCardWidget extends ConsumerWidget {
  final DirectoryConfig directory;
  final VoidCallback onRemove;

  const DirectoryCardWidget({
    required this.directory,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with path and action buttons
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.directoryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        directory.path,
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
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    directory.isWatched
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 16,
                  ),
                  label: Text(
                    directory.isWatched ? 'Watched' : 'Not watched',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                if (directory.includeSubdirectories)
                  const Chip(
                    avatar: Icon(Icons.folder_open, size: 16),
                    label: Text('Includes subdirectories',
                        style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (directory.indexedFileCount != null)
                  Chip(
                    avatar: const Icon(Icons.insert_drive_file, size: 16),
                    label: Text(
                      '${directory.indexedFileCount} files',
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            // File extensions
            if (directory.fileExtensions.isNotEmpty &&
                !directory.includesAllFileTypes) ...[
              const SizedBox(height: 8),
              Text(
                'File types: ${directory.fileExtensionsFormatted}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Last indexed time
            if (directory.hasBeenIndexed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last indexed: ${directory.lastIndexedFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
