// Run with: dart run tool/coverage.dart [--min=<percent>] [--exclude=<glob>] [--skip-tests] [--no-clean]
//
// This script executes `flutter test --coverage`, parses the generated
// `lcov.info`, and prints a simple coverage summary. It supports optional
// thresholds and excludes to keep generated code out of the report.

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final settings = CoverageSettings.parse(arguments);

  final coverageDir = Directory('coverage');
  if (settings.clean && coverageDir.existsSync()) {
    stdout.writeln('Cleaning previous coverage artifacts…');
    coverageDir.deleteSync(recursive: true);
  }

  if (settings.runTests) {
    stdout.writeln('Running flutter test with coverage…');
    final process = await Process.start(
        'flutter',
        [
          'test',
          '--coverage',
          if (settings.coveragePathOverride != null) ...[
            '--coverage-path',
            settings.coveragePathOverride!,
          ],
        ],
        runInShell: true);

    unawaited(stdout.addStream(process.stdout));
    unawaited(stderr.addStream(process.stderr));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('flutter test exited with code $exitCode');
      exit(exitCode);
    }
  }

  final coveragePath = settings.coveragePathOverride ?? 'coverage/lcov.info';
  final coverageFile = File(coveragePath);
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found at $coveragePath.');
    stderr.writeln('Re-run with --skip-tests only if the file already exists.');
    exit(1);
  }

  final summary = LcovSummary.parse(
    coverageFile.readAsLinesSync(),
    excludes: settings.excludePatterns,
  );

  stdout.writeln();
  stdout.writeln('Coverage summary');
  stdout.writeln('  Files analyzed : ${summary.files}');
  stdout.writeln(
    '  Lines covered  : ${summary.linesHit}/${summary.linesFound}',
  );
  stdout.writeln(
    '  Line coverage : ${summary.coveragePercent.toStringAsFixed(2)}%',
  );

  if (summary.linesFound == 0) {
    stderr.writeln('No executable lines were found.');
    exit(1);
  }

  final threshold = settings.minimumCoverage;
  if (threshold != null && summary.coveragePercent < threshold) {
    stderr.writeln(
      'Coverage ${summary.coveragePercent.toStringAsFixed(2)}% '
      'is below required minimum ${threshold.toStringAsFixed(2)}%.',
    );
    exit(2);
  }

  stdout.writeln('Coverage check complete.');
}

class CoverageSettings {
  CoverageSettings({
    required this.minimumCoverage,
    required this.excludePatterns,
    required this.runTests,
    required this.clean,
    required this.coveragePathOverride,
  });

  final double? minimumCoverage;
  final List<RegExp> excludePatterns;
  final bool runTests;
  final bool clean;
  final String? coveragePathOverride;

  static CoverageSettings parse(List<String> arguments) {
    double? minimumCoverage;
    var runTests = true;
    var clean = true;
    String? coveragePathOverride;
    final excludePatterns = <RegExp>[
      RegExp(r'.*\.g\.dart$'),
      RegExp(r'.*\.freezed\.dart$'),
      RegExp(r'.*\.gen\.dart$'),
      RegExp(r'.*/generated_plugin_registrant\.dart$'),
    ];

    void printUsage() {
      stdout.writeln('Usage: dart run tool/coverage.dart [options]');
      stdout.writeln();
      stdout.writeln('Options:');
      stdout.writeln(
        '  --min=<percent>        Minimum line coverage required (e.g. 75 or 75.5).',
      );
      stdout.writeln(
        '  --exclude=<glob>       Exclude files matching glob (may be repeated).',
      );
      stdout.writeln(
        '  --coverage-path=<path> Custom coverage output to read (default coverage/lcov.info).',
      );
      stdout.writeln(
        '  --skip-tests          Skip running flutter test and only parse existing report.',
      );
      stdout.writeln(
        '  --no-clean            Keep existing coverage artifacts instead of deleting them.',
      );
      stdout.writeln('  --help                Show this message.');
    }

    for (final raw in arguments) {
      if (raw == '--help') {
        printUsage();
        exit(0);
      } else if (raw.startsWith('--min=')) {
        final value = double.tryParse(raw.substring(6));
        if (value == null || value < 0 || value > 100) {
          stderr.writeln('Invalid --min value: ${raw.substring(6)}');
          exit(64); // EX_USAGE
        }
        minimumCoverage = value;
      } else if (raw.startsWith('--exclude=')) {
        final pattern = raw.substring(10);
        excludePatterns.add(_globToRegExp(pattern));
      } else if (raw == '--skip-tests') {
        runTests = false;
      } else if (raw == '--no-clean') {
        clean = false;
      } else if (raw.startsWith('--coverage-path=')) {
        coveragePathOverride = raw.substring(16);
      } else {
        stderr.writeln('Unknown argument: $raw');
        printUsage();
        exit(64);
      }
    }

    return CoverageSettings(
      minimumCoverage: minimumCoverage,
      excludePatterns: excludePatterns,
      runTests: runTests,
      clean: clean,
      coveragePathOverride: coveragePathOverride,
    );
  }
}

class LcovSummary {
  LcovSummary({
    required this.files,
    required this.linesFound,
    required this.linesHit,
  });

  final int files;
  final int linesFound;
  final int linesHit;

  double get coveragePercent =>
      linesFound == 0 ? 0 : (linesHit / linesFound) * 100;

  static LcovSummary parse(
    List<String> lines, {
    required List<RegExp> excludes,
  }) {
    var files = 0;
    var totalFound = 0;
    var totalHit = 0;

    String? currentFile;
    var skip = false;
    var recordFound = 0;
    var recordHit = 0;

    for (final raw in lines) {
      if (raw.startsWith('SF:')) {
        currentFile = raw.substring(3).trim();
        skip = excludes.any((pattern) => pattern.hasMatch(currentFile!));
        recordFound = 0;
        recordHit = 0;
      } else if (raw.startsWith('LF:')) {
        recordFound = int.tryParse(raw.substring(3).trim()) ?? recordFound;
      } else if (raw.startsWith('LH:')) {
        recordHit = int.tryParse(raw.substring(3).trim()) ?? recordHit;
      } else if (raw == 'end_of_record') {
        if (!skip && currentFile != null) {
          files += 1;
          totalFound += recordFound;
          totalHit += recordHit;
        }
        currentFile = null;
        skip = false;
        recordFound = 0;
        recordHit = 0;
      }
    }

    return LcovSummary(
      files: files,
      linesFound: totalFound,
      linesHit: totalHit,
    );
  }
}

RegExp _globToRegExp(String pattern) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    switch (char) {
      case '*':
        buffer.write('.*');
        break;
      case '?':
        buffer.write('.');
        break;
      case '.':
      case r'$':
      case '^':
      case '+':
      case '(':
      case ')':
      case '[':
      case ']':
      case '{':
      case '}':
      case '|':
      case '\\':
        buffer.write('\\$char');
        break;
      default:
        buffer.write(char);
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}
