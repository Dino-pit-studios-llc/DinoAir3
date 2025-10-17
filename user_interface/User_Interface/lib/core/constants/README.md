# core/constants

Central place for design tokens and static constant values used across features.

Suggested files:

- spacing.dart: Edge insets, gaps (e.g. `const gap8 = SizedBox(width: 8, height: 8);` or numeric constants).
- durations.dart: Animation + debounce durations.
- breakpoints.dart: Responsive thresholds for layout decisions.
- semantic_colors.dart: Names like `gainColor`, `lossColor`, `neutralBg` (resolved in theme layer).

Why centralize:

- Keeps styling consistent & tweakable.
- Prevents magic numbers scattered in UI code.

DO NOT put:

- Dynamic/runtime values (those belong in providers/services).
