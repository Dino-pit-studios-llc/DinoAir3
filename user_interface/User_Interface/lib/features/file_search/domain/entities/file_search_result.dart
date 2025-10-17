import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_search_result.freezed.dart';

@freezed
class FileSearchResult with _$FileSearchResult {
  const factory FileSearchResult({
    required String filePath,
    required String fileName,
    required String fileType,
    required int fileSize,
    required DateTime lastModified,
    required double relevanceScore,
    required List<String> matchedKeywords,
    String? fileContent,
    Map<String, dynamic>? metadata,
  }) = _FileSearchResult;

  const FileSearchResult._();

  /// Format file size to human-readable string
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get file extension from filename
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is a code file
  bool get isCodeFile {
    const codeExtensions = [
      'dart',
      'py',
      'js',
      'ts',
      'java',
      'cpp',
      'c',
      'go',
      'rs',
      'swift',
      'kt',
      'rb',
      'php',
      'cs',
      'html',
      'css',
      'scss',
      'sass',
    ];
    return codeExtensions.contains(fileExtension);
  }

  /// Check if file is a document
  bool get isDocument {
    const docExtensions = [
      'txt',
      'md',
      'doc',
      'docx',
      'pdf',
      'rtf',
      'odt',
    ];
    return docExtensions.contains(fileExtension);
  }

  /// Check if file is a config file
  bool get isConfigFile {
    const configExtensions = [
      'json',
      'yaml',
      'yml',
      'xml',
      'toml',
      'ini',
      'config',
      'env',
    ];
    return configExtensions.contains(fileExtension);
  }

  /// Check if file is an image
  bool get isImage {
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'svg',
      'webp',
      'ico',
    ];
    return imageExtensions.contains(fileExtension);
  }
}
