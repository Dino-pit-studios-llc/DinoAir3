# features/settings/domain

Domain layer for user preferences.

Include:

- Entities / value objects: `ThemeModePreference`, `CurrencyPreference`
- Repository interface: `SettingsRepository` (get/set theme mode, get/set fiat currency)
- Use cases: `GetThemeModeUseCase`, `SetThemeModeUseCase`, `GetCurrencyUseCase`, `SetCurrencyUseCase`

Guidelines:

- Avoid exposing persistence-specific details (e.g. SharedPreferences keys)
- Provide defaults (system theme, USD) if nothing stored

Testing:

- Mock repository to verify use cases drive correct methods
