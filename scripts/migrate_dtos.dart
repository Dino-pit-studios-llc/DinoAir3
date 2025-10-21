/// DTO Migration Script
/// 
/// This script helps identify and fix DTOs with duplicate JSON serialization annotations.
/// 
/// Usage:
///   dart run scripts/migrate_dtos.dart [options]
/// 
/// Options:
///   --check    Only check for issues, don't fix
///   --fix      Automatically fix duplicate annotations
///   --help     Show this help message
///
/// Problem:
/// Some DTOs incorrectly use BOTH @freezed and @JsonSerializable annotations.
/// Freezed automatically handles JSON serialization when you include the .g.dart part file.
/// The @JsonSerializable annotation is redundant and causes duplicate code generation.
///
/// Correct Pattern:
/// ```dart
/// import 'package:freezed_annotation/freezed_annotation.dart';
/// 
/// part 'my_dto.freezed.dart';
/// part 'my_dto.g.dart';
/// 
/// @freezed
/// class MyDTO with _$MyDTO {
///   const factory MyDTO({
///     required String field,
///   }) = _MyDTO;
///   
///   factory MyDTO.fromJson(Map<String, dynamic> json) => 
///       _$MyDTOFromJson(json);
/// }
/// ```

import 'dart:io';

void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    printHelp();
    return;
  }

  final checkOnly = arguments.contains('--check');
  final autoFix = arguments.contains('--fix');

  if (!checkOnly && !autoFix) {
    print('Please specify --check or --fix');
    print('Run with --help for more information');
    exit(1);
  }

  print('🔍 Scanning for DTOs with duplicate annotations...\n');

  final issues = scanForIssues();

  if (issues.isEmpty) {
    print('✅ No issues found! All DTOs are correctly configured.');
    return;
  }

  print('❌ Found ${issues.length} file(s) with duplicate annotations:\n');

  for (final issue in issues) {
    print('  📁 ${issue.relativePath}');
    print('     Line ${issue.line}: ${issue.annotation}');
    print('');
  }

  if (checkOnly) {
    print('\n💡 Run with --fix to automatically remove duplicate annotations');
    exit(1);
  }

  if (autoFix) {
    print('\n🔧 Fixing issues...\n');
    for (final issue in issues) {
      fixIssue(issue);
    }
    print('✅ All issues fixed!');
    print('\n📋 Next steps:');
    print('   1. cd user_interface/User_Interface');
    print('   2. flutter pub run build_runner build --delete-conflicting-outputs');
    print('   3. flutter analyze');
    print('   4. flutter test');
  }
}

List<DuplicateAnnotationIssue> scanForIssues() {
  final issues = <DuplicateAnnotationIssue>[];
  final libDir = Directory('user_interface/User_Interface/lib');

  if (!libDir.existsSync()) {
    print('⚠️  Warning: Flutter lib directory not found');
    return issues;
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.dart') &&
          !f.path.endsWith('.freezed.dart') &&
          !f.path.endsWith('.g.dart'));

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    bool hasFreezed = false;
    int? freezedLine;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('@freezed') || line.startsWith('@Freezed')) {
        hasFreezed = true;
        freezedLine = i + 1;
      }

      if (hasFreezed && line.startsWith('@JsonSerializable')) {
        issues.add(DuplicateAnnotationIssue(
          filePath: file.path,
          relativePath: file.path.replaceAll('\\', '/').split('lib/').last,
          line: i + 1,
          annotation: line,
          freezedLine: freezedLine!,
        ));
      }

      // Reset when we hit a class declaration
      if (line.startsWith('class ')) {
        hasFreezed = false;
        freezedLine = null;
      }
    }
  }

  return issues;
}

void fixIssue(DuplicateAnnotationIssue issue) {
  final file = File(issue.filePath);
  final lines = file.readAsLinesSync();

  // Remove the @JsonSerializable line
  lines.removeAt(issue.line - 1);

  file.writeAsStringSync(lines.join('\n') + '\n');

  print('✅ Fixed: ${issue.relativePath}');
}

void printHelp() {
  print('''
DTO Migration Script

Usage:
  dart run scripts/migrate_dtos.dart [options]

Options:
  --check    Only check for issues, don't fix
  --fix      Automatically fix duplicate annotations
  --help     Show this help message

Description:
  This script identifies DTOs that incorrectly use BOTH @freezed and 
  @JsonSerializable annotations. Freezed automatically handles JSON 
  serialization, so @JsonSerializable is redundant.

Examples:
  dart run scripts/migrate_dtos.dart --check  # Check for issues
  dart run scripts/migrate_dtos.dart --fix    # Fix issues automatically

After fixing:
  cd user_interface/User_Interface
  flutter pub run build_runner build --delete-conflicting-outputs
  flutter analyze
  flutter test
''');
}

class DuplicateAnnotationIssue {
  final String filePath;
  final String relativePath;
  final int line;
  final String annotation;
  final int freezedLine;

  DuplicateAnnotationIssue({
    required this.filePath,
    required this.relativePath,
    required this.line,
    required this.annotation,
    required this.freezedLine,
  });
}
