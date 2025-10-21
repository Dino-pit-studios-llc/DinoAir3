import 'dart:io';

/// Utility for reading test fixture files
///
/// Usage:
/// ```dart
/// final jsonString = fixture('chat_message.json');
/// final json = jsonDecode(jsonString);
/// ```
String fixture(String name) {
  final file = File('test/fixtures/$name');
  if (!file.existsSync()) {
    throw Exception('Fixture file not found: $name');
  }
  return file.readAsStringSync();
}
