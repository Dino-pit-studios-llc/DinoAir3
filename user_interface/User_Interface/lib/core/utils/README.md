# core/utils

Stateless, pure utility helpers used across multiple features.

Examples to add:

- number_format.dart (abbreviate large numbers, e.g. 1.2M)
- percent_format.dart (format +/- percentages with sign)
- debounce.dart (generic debounce wrapper if needed outside UI)
- date_time_utils.dart (time range boundaries for charts)

Rules:

- Functions should not depend on Flutter widgets; keep them platform-agnostic.
- Avoid feature-specific logic (e.g. watchlist-specific sorting belongs in that feature).

Testing:

- Each utility file should have a corresponding \*\_test.dart verifying edge cases (null/empty, negative numbers, very large values).
