# lib/features

All vertical application features. Each feature owns its presentation (UI), domain (business rules), and data (integration) layers under its own folder.

Structure pattern:
feature_name/
domain/ // Entities, repository interfaces, use cases
data/ // DTOs, data sources (remote/local), mappers, repository impls
presentation/ // Widgets, screens, providers/controllers, view models

Why this layout:

- Keeps feature concerns cohesive and discoverable.
- Reduces cross-feature coupling; easier to extract or refactor a feature.
- Encourages thin UI & stable domain contracts.

Conventions:

- Do not import `presentation/` from `domain/` or `data/`.
- Domain is pure Dart (no Flutter imports).
- Data layer never exposes raw DTOs outside itself; only domain entities leave.

Testing strategy:

- Unit test domain first (fast feedback, high value).
- Mock repositories in use case tests.
- Provide fake providers / overrides in widget tests.

Existing features:

- market
- watchlist (to add)
- portfolio (to add)
- settings (to add, lighter: may only need presentation + a small domain piece for preferences)

Add new features by mirroring this structure.
