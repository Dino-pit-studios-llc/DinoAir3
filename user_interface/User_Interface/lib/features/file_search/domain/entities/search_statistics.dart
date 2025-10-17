import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_statistics.freezed.dart';

@freezed
class SearchStatistics with _$SearchStatistics {
  const factory SearchStatistics({
    required int totalFiles,
    required int indexedFiles,
    required int totalDirectories,
    required DateTime lastIndexTime,
    required Map<String, int> fileTypeDistribution,
  }) = _SearchStatistics;

  const SearchStatistics._();

  /// Calculate indexing percentage
  double get indexingPercentage {
    if (totalFiles == 0) return 0.0;
    return (indexedFiles / totalFiles * 100).clamp(0.0, 100.0);
  }

  /// Check if indexing is complete
  bool get isIndexingComplete => indexedFiles >= totalFiles;

  /// Get the most common file type
  String? get mostCommonFileType {
    if (fileTypeDistribution.isEmpty) return null;

    final sorted = fileTypeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  /// Get formatted last index time
  String get lastIndexTimeFormatted {
    final now = DateTime.now();
    final diff = now.difference(lastIndexTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${lastIndexTime.day}/${lastIndexTime.month}/${lastIndexTime.year}';
  }

  /// Get top N file types by count
  List<MapEntry<String, int>> getTopFileTypes(int count) {
    final sorted = fileTypeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).toList();
  }
}
