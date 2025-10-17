# core/errors

Defines failure and error abstraction used across the app.

Planned components (A5):

- failure.dart: Sealed class / sealed hierarchy (`sealed class Failure {}`) with subtypes: `NetworkFailure`, `ApiFailure`, `CacheFailure`, `ParsingFailure`, `UnknownFailure`.
- exception_mapping.dart: Maps thrown exceptions (e.g. DioError, FormatException) to `Failure` instances.
- error_messages.dart: User-facing message translator (Failure -> localized string) — logic stays here or in a thin helper.

Why centralize:

- Consistent user messaging.
- Prevents UI from depending on low-level exception types.

Testing:

- Unit test mapping for each external exception scenario.
