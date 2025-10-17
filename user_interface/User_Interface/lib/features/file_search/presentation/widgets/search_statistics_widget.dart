import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_search_providers.dart';

/// Widget that displays search index statistics
class SearchStatisticsWidget extends ConsumerWidget {
  const SearchStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(searchStatisticsProvider);
    final directoriesCount = ref.watch(watchedDirectoriesCountProvider);

    return statsAsync.when(
      data: (stats) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.folder,
                  label: 'Directories',
                  value: directoriesCount.toString(),
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  icon: Icons.insert_drive_file,
                  label: 'Indexed Files',
                  value: stats.indexedFiles.toString(),
                  color: theme.colorScheme.secondary,
                ),
                _StatItem(
                  icon: Icons.pie_chart,
                  label: 'Indexing',
                  value: '${stats.indexingPercentage.toStringAsFixed(0)}%',
                  color: stats.isIndexingComplete
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (error, stack) => const Card(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Text('Failed to load statistics'),
        ),
      ),
    );
  }
}

/// Individual stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
