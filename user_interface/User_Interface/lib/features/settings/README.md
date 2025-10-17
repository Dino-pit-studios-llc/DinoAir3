# features/settings

Handles user preferences and configuration surfaces.

Responsibilities:

- Theme mode selection (system / light / dark) (F19)
- Fiat currency preference (USD/EUR ...) (F20)
- Potential future: number format, language selection, data refresh interval.

Subfolders (when implemented):

- domain/: Preference entities/value objects (e.g. `ThemePreference`), repository interface for settings persistence, use cases like `SetThemeModeUseCase`.
- data/: Local persistence adapter (SharedPreferences / Hive), repository implementation mapping raw storage to domain abstractions.
- presentation/: Settings screen, preference tiles/widgets, providers holding current preference state.

Why separate:

- Prevents scattering preference logic throughout features.
- Central point for adding more preferences later without refactoring other layers.

Design notes:

- Riverpod providers expose current preferences; other features can watch them to adapt UI (e.g. currency formatting).
- Keep persistence simple initially (SharedPreferences); abstract behind repository so moving to Hive is trivial.

Testing:

- Repository tests: read/write preference roundtrip.
- Widget test: toggling theme updates provider & triggers MaterialApp rebuild (with override).
