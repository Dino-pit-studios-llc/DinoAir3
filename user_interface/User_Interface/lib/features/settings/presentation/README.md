# features/settings/presentation

UI + state layer for Settings feature.

Include:

- screen/: `SettingsScreen` listing preference tiles.
- widgets/: Reusable preference tiles (theme selector, currency picker).
- providers/: Riverpod providers exposing current theme mode & currency (e.g. `themeModeProvider`, `currencyProvider`).
- controllers/: Notifiers invoking domain use cases to persist changes.

Patterns:

- Use `DropdownButton`, `SegmentedButton`, or custom chips for currency/theme choices.
- Theme provider triggers rebuild of `MaterialApp` (listen at app root) when value changes.

Testing:

- Widget test: toggling theme updates provider and rebuilds a sample widget (light -> dark differences).
- Provider test: currency selection persists and reloads correctly when repository returns stored value.
