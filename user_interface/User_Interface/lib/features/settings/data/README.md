# features/settings/data

Persistence implementation for user preferences.

Include:

- local/: Adapter around SharedPreferences or Hive box
- models/: Only if serialized form differs meaningfully from domain (usually simple primitives, so may skip)
- repository/: `SettingsRepositoryImpl` mapping raw storage to domain value objects

Responsibilities:

- Read/write theme mode & fiat currency synchronously/asynchronously
- Migrate legacy keys if schema changes (version marker optional)

Guidelines:

- Keep keys centralized (e.g. `const _kThemeModeKey = 'theme_mode';`)
- Wrap external exceptions and surface controlled errors (mapped to Failure if needed)

Testing:

- Use in-memory fake (for SharedPreferences: setMockInitialValues) to validate round trips
