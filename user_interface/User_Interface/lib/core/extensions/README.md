# core/extensions

Extension methods that add narrowly-scoped convenience to existing types.

Examples (planned):

- `num_format_extensions.dart`: `double.asCompactCurrency()` wrapping intl formatting.
- `iterable_extensions.dart`: Safe min/max helpers, chunking.
- `async_extensions.dart`: Convenience for retry/backoff (if widely reused).

Guidelines:

- Keep each extension file focused (avoid giant grab-bag files).
- Avoid polluting global API with overly generic names.
- Do not introduce feature-specific semantics (those belong in that feature's presentation or domain layer).

Testing:

- Unit test each extension's edge cases (null not applicable since extensions can't apply to null safety types, but test empty collections, large numbers, negatives, etc.).
