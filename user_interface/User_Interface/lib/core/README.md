# lib/core

Cross-cutting foundational code shared across features.

What belongs here:

- constants/: Spacing, durations, breakpoints, semantic color names.
- errors/: Failure & exception abstractions. (Checklist A5)
- utils/: Pure stateless helpers (formatting, number abbreviations, percentage calc).
- theme/: Theme extensions, color scheme builders, typography tokens. (A6)
- extensions/: Dart/Flutter extension methods (e.g. `num.toCurrencyString()`).

Why isolate core:

- Prevents circular dependencies: Features depend on core, never the reverse.
- Shared primitives live in one place (reduces duplication and drift).

Anti-patterns:

- No feature-specific logic (e.g. market repository logic goes under `features/market`).
- Avoid dumping everything here; if a file is only used by one feature, keep it in that feature.

Testing guidance:

- Core utilities should have fast unit tests (deterministic, no I/O).

Next steps:

- (A5) Introduce `Failure` sealed class (e.g. `NetworkFailure`, `ParseFailure`).
- (A6) Add theme folder with semantic color mapping (gain/loss, neutral, warning).
