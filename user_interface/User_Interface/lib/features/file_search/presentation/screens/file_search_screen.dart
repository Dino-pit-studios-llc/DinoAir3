import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/file_search_providers.dart';
import '../widgets/search_results_list_widget.dart';
import '../widgets/search_statistics_widget.dart';

/// Main file search screen with search bar, filters, and results
class FileSearchScreen extends ConsumerStatefulWidget {
  const FileSearchScreen({super.key});

  @override
  ConsumerState<FileSearchScreen> createState() => _FileSearchScreenState();
}

class _FileSearchScreenState extends ConsumerState<FileSearchScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final fileTypes = ref.read(selectedFileTypesProvider);
    final directories = ref.read(selectedDirectoriesProvider);
    final maxResults = ref.read(maxResultsProvider);

    ref.read(fileSearchProvider.notifier).search(
          query: query,
          fileTypes: fileTypes.isEmpty ? null : fileTypes,
          directories: directories.isEmpty ? null : directories,
          maxResults: maxResults,
        );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(fileSearchProvider.notifier).clear();
    ref.read(selectedFileTypesProvider.notifier).state = [];
    ref.read(selectedDirectoriesProvider.notifier).state = [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(fileSearchProvider);
    final resultsCount = ref.watch(searchResultsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Search'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Hide filters' : 'Show filters',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              context.push('/file-search/directories');
            },
            tooltip: 'Manage directories',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files by keyword...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filters section (collapsible)
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _FiltersSection(
                onFilterChanged: _performSearch,
              ),
            ),

          // Statistics
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchStatisticsWidget(),
          ),

          // Results count
          if (resultsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$resultsCount result${resultsCount == 1 ? '' : 's'} found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          const Divider(height: 16),

          // Results
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty
                              ? Icons.search
                              : Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Enter a search query to find files'
                              : 'No files found matching your search',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SearchResultsListWidget(results: results);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _performSearch,
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
      floatingActionButton: _searchController.text.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _performSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            )
          : null,
    );
  }
}

/// Filters section widget for file types and directories
class _FiltersSection extends ConsumerWidget {
  final VoidCallback onFilterChanged;

  const _FiltersSection({required this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFileTypes = ref.watch(selectedFileTypesProvider);
    final selectedDirectories = ref.watch(selectedDirectoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // File types filter
            Text(
              'File Types',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Code',
                  icon: Icons.code,
                  isSelected: selectedFileTypes.contains('code'),
                  onSelected: (selected) {
                    final types = List<String>.from(selectedFileTypes);
                    if (selected) {
                      types.add('code');
                    } else {
                      types.remove('code');
                    }
                    ref.read(selectedFileTypesProvider.notifier).state = types;
                    onFilterChanged();
                  },
                ),
                _FilterChip(
                  label: 'Documents',
                  icon: Icons.description,
                  isSelected: selectedFileTypes.contains('documents'),
                  onSelected: (selected) {
                    final types = List<String>.from(selectedFileTypes);
                    if (selected) {
                      types.add('documents');
                    } else {
                      types.remove('documents');
                    }
                    ref.read(selectedFileTypesProvider.notifier).state = types;
                    onFilterChanged();
                  },
                ),
                _FilterChip(
                  label: 'Images',
                  icon: Icons.image,
                  isSelected: selectedFileTypes.contains('images'),
                  onSelected: (selected) {
                    final types = List<String>.from(selectedFileTypes);
                    if (selected) {
                      types.add('images');
                    } else {
                      types.remove('images');
                    }
                    ref.read(selectedFileTypesProvider.notifier).state = types;
                    onFilterChanged();
                  },
                ),
                _FilterChip(
                  label: 'Config',
                  icon: Icons.settings,
                  isSelected: selectedFileTypes.contains('config'),
                  onSelected: (selected) {
                    final types = List<String>.from(selectedFileTypes);
                    if (selected) {
                      types.add('config');
                    } else {
                      types.remove('config');
                    }
                    ref.read(selectedFileTypesProvider.notifier).state = types;
                    onFilterChanged();
                  },
                ),
              ],
            ),

            if (selectedFileTypes.isNotEmpty ||
                selectedDirectories.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ref.read(selectedFileTypesProvider.notifier).state = [];
                  ref.read(selectedDirectoriesProvider.notifier).state = [];
                  onFilterChanged();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
