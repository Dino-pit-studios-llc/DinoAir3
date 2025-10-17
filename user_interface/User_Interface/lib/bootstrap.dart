/// Application bootstrap entrypoint.
///
/// Why:
///  - Centralize all async initialization before `runApp`: ensures widgets build only after
///    services, local storage, and environment variables are ready.
///  - Keeps `main.dart` minimal and focused on wiring the root widget tree.
///
/// Typical responsibilities (add as implemented):
///  1. Ensure Flutter binding is initialized.
///  2. Load environment variables (`flutter_dotenv`).
///  3. Initialize local storage (Hive boxes / SharedPreferences).
///  4. Set up dependency injection / service singletons.
///  5. Warm up caches (optional, e.g. last market snapshot).
///  6. Set error handlers (Flutter + Zone) for logging.
///
/// Future extension: Pass a configuration object (e.g. flavor, base urls) or override
/// dependencies for tests (e.g. injecting mock API clients).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _sentryDsnDefine = String.fromEnvironment('SENTRY_DSN');
const String _sentryEnvDefine = String.fromEnvironment('SENTRY_ENV');
const String _sentryReleaseDefine = String.fromEnvironment('SENTRY_RELEASE');
const String _sentryTracesSampleRateDefine = String.fromEnvironment(
  'SENTRY_TRACES_SAMPLE_RATE',
);

Future<void> bootstrap(
  Future<Widget> Function(SharedPreferences) builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env) early so providers can read them.
  try {
    await dotenv.load();
  } catch (_) {
    // Silently ignore if .env missing; dart-define or other methods may supply keys.
  }

  // Initialize SharedPreferences for local storage
  final prefs = await SharedPreferences.getInstance();

  // Global error handling:
  // - When Sentry DSN is supplied, SentryFlutter.init wires error/zone handlers.
  // - Without Sentry, `_installFallbackErrorHandlers` keeps errors visible in logs.

  Future<void> runAppWithBootstrap() async {
    final rootWidget = await builder(prefs);
    runApp(rootWidget);
  }

  final sentryDsn = _resolveConfig(
    dotenv.maybeGet('SENTRY_DSN'),
    _sentryDsnDefine,
  );
  if (sentryDsn.isEmpty) {
    debugPrint('Sentry DSN not provided; skipping Sentry initialization.');
    _installFallbackErrorHandlers();
    await runAppWithBootstrap();
    return;
  }

  final sentryEnvironment = _resolveConfig(
    dotenv.maybeGet('SENTRY_ENV'),
    _sentryEnvDefine,
  );
  final sentryRelease = _resolveConfig(
    dotenv.maybeGet('SENTRY_RELEASE'),
    _sentryReleaseDefine,
  );
  final tracesSampleRate = _resolveTracesSampleRate(
    dotenv.maybeGet('SENTRY_TRACES_SAMPLE_RATE'),
    _sentryTracesSampleRateDefine,
  );

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.tracesSampleRate = tracesSampleRate ?? 0.2;
    if (sentryEnvironment.isNotEmpty) {
      options.environment = sentryEnvironment;
    }
    if (sentryRelease.isNotEmpty) {
      options.release = sentryRelease;
    }
  }, appRunner: runAppWithBootstrap);
}

String _resolveConfig(String? envValue, String defineValue) {
  final value = envValue?.trim();
  if (value != null && value.isNotEmpty) {
    return value;
  }
  final define = defineValue.trim();
  if (define.isNotEmpty) {
    return define;
  }
  return '';
}

double? _resolveTracesSampleRate(String? envValue, String defineValue) {
  final raw = _resolveConfig(envValue, defineValue);
  if (raw.isEmpty) {
    return null;
  }
  final parsed = double.tryParse(raw);
  if (parsed == null) {
    debugPrint(
      'Invalid SENTRY_TRACES_SAMPLE_RATE value "$raw"; using default.',
    );
    return null;
  }
  final clamped = parsed.clamp(0.0, 1.0);
  if (clamped != parsed) {
    debugPrint(
      'SENTRY_TRACES_SAMPLE_RATE value "$parsed" clamped to "$clamped".',
    );
  }
  return clamped;
}

void _installFallbackErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  dispatcher.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('Unhandled platform dispatcher error'),
      ),
    );
    return true;
  };
}
