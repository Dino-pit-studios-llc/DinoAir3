# core/theme

Centralized theming utilities and extensions.

Implemented (A - Theming phase):

- `color_schemes.dart`: Brand palette + generated `lightColorScheme` / `darkColorScheme` using seed color (#9440DD) and
  secondary (#F87109) + tertiary (#00D8FD).
- `semantic_colors.dart`: `SemanticColors` ThemeExtension (gain, loss, warning, subtleBg, accent) with light/dark
  builders.
- `app_theme.dart`: `buildLightTheme()` / `buildDarkTheme()` wiring color schemes + semantic extension and some
  component defaults (Card, Chip).
- Providers (in `features/settings/presentation/providers/theme_providers.dart`): theme mode controller +
  `lightThemeProvider` / `darkThemeProvider`.
- UI integration: `MarketScreen` now uses semantic gain/loss colors and adds a theme mode cycle icon (system → light →
  dark).

Brand Color Tokens:

```
Primary  #9440DD  (vivid purple)
Secondary #F87109 (orange)
Tertiary #00D8FD  (vivid azure; corrected from provided typo #0od8fd2)
```

How to access semantic colors inside a widget:

```dart

final semantic = Theme.of(context).extension<SemanticColors>();
final gainColor = semantic?.gain;
```

How to change theme mode programmatically:

```dart
ref.read
(
themeModeControllerProvider.notifier).set(AppThemeMode.dark);
```

Default Behavior:

- App launches in `AppThemeMode.system` (resolves to device preference).
- MARKET_DATA_SOURCE defaults to CoinMarketCap (unless overridden by `--dart-define` or `.env`).
- If `CMC_API_KEY` missing while using CoinMarketCap, a red warning chip appears beneath AppBar.

Next Potential Enhancements:

1. Typography scale override (e.g., custom display / title weights).
2. Add high-contrast palette variant (A11y) via additional ThemeExtension.
3. Animate theme mode transitions (`ThemeModeSwitcher` / implicit animations).
4. Expose semantic colors for neutral separators / accent outlines.
5. Add test ensuring light/dark semantic colors differ where expected.

Testing Ideas:

- Widget test asserting gain/loss colors applied to positive/negative price changes.
- Golden tests for light vs dark `MarketScreen`.

Guidelines:

- Keep raw hex values here; elsewhere rely on `ColorScheme` or `SemanticColors`.
- Prefer semantic usage (e.g., `semantic.gain`) instead of direct green/red for domain meaning.
