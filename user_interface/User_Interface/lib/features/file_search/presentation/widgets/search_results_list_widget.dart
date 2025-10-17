import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/file_search_result.dart';
import 'file_result_card_widget.dart';

/// Widget that displays a scrollable list of file search results
class SearchResultsListWidget extends ConsumerWidget {
  final List<FileSearchResult> results;

  const SearchResultsListWidget({
    required this.results,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return FileResultCardWidget(result: result);
      },
    );
  }
}
