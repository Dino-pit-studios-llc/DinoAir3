/// Utility class for file type classification based on file extensions
class FileTypeClassifier {
  FileTypeClassifier._();

  /// List of code file extensions
  static const codeExtensions = [
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

  /// List of document file extensions
  static const docExtensions = [
    'txt',
    'md',
    'doc',
    'docx',
    'pdf',
    'rtf',
    'odt',
  ];

  /// List of config file extensions
  static const configExtensions = [
    'json',
    'yaml',
    'yml',
    'xml',
    'toml',
    'ini',
    'config',
    'env',
  ];

  /// List of image file extensions
  static const imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'svg',
    'webp',
    'ico',
  ];

  /// Check if the file extension is a code file
  static bool isCodeFile(String extension) {
    return codeExtensions.contains(extension.toLowerCase());
  }

  /// Check if the file extension is a document
  static bool isDocument(String extension) {
    return docExtensions.contains(extension.toLowerCase());
  }

  /// Check if the file extension is a config file
  static bool isConfigFile(String extension) {
    return configExtensions.contains(extension.toLowerCase());
  }

  /// Check if the file extension is an image
  static bool isImage(String extension) {
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Get file extension from filename
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
