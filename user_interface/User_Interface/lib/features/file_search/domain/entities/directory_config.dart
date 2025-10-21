import 'package:freezed_annotation/freezed_annotation.dart';

part 'directory_config.freezed.dart';

@freezed
class DirectoryConfig with _$DirectoryConfig {
  const factory DirectoryConfig({
    required String path,
    required bool isWatched,
    required bool includeSubdirectories,
    required List<String> fileExtensions,
    DateTime? lastIndexed,
    int? indexedFileCount,
  }) = _DirectoryConfig;

  const DirectoryConfig._();

  /// Check if directory has been indexed
  bool get hasBeenIndexed => lastIndexed != null;

  /// Get human-readable last indexed time
  String get lastIndexedFormatted {
    if (lastIndexed == null) return 'Never indexed';

    final now = DateTime.now();
    final diff = now.difference(lastIndexed!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${lastIndexed!.day}/${lastIndexed!.month}/${lastIndexed!.year}';
  }

  /// Get directory name from path
  String get directoryName {
    final parts = path.split(RegExp(r'[/\\]'));
    final nonEmptyParts = parts.where((p) => p.isNotEmpty).toList();
    return nonEmptyParts.isNotEmpty ? nonEmptyParts.last : path;
  }

  /// Check if all file types are included
  bool get includesAllFileTypes => fileExtensions.isEmpty;

  /// Get formatted file extensions list
  String get fileExtensionsFormatted {
    if (includesAllFileTypes) return 'All file types';
    if (fileExtensions.length <= 3) {
      return fileExtensions.map((e) => '.$e').join(', ');
    }
    return '${fileExtensions.take(3).map((e) => '.$e').join(', ')} +${fileExtensions.length - 3} more';
  }
}
