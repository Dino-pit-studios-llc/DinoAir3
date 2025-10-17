import 'exception_mapping.dart';
import 'failure.dart';

/// Wraps async operations and converts thrown exceptions into [Failure]s.
Future<T> guardFuture<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (error, stackTrace) {
    throw mapException(error, stackTrace);
  }
}

/// Guard for synchronous operations.
T guard<T>(T Function() operation) {
  try {
    return operation();
  } catch (error, stackTrace) {
    throw mapException(error, stackTrace);
  }
}

/// Utility to run an async operation and capture the [Failure] instead of throwing it.
Future<Failure?> tryGuard(Future<void> Function() operation) async {
  try {
    await operation();
    return null;
  } catch (error) {
    if (error is Failure) return error;
    return UnknownFailure(message: error.toString(), cause: error);
  }
}
