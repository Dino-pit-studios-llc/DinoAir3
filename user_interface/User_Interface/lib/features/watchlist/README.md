# features/watchlist

Manages the user's personalized list of favorited coins.

Responsibilities:

- Add/remove (toggle) watchlist items.
- Persist watchlist locally (Hive box / SharedPreferences) (F13).
- Expose reactive list to other features (e.g. market list highlight, dedicated watchlist tab).
- Optionally sync with backend if future auth is added.

Subfolders (to create as populated):

- domain/: `WatchlistRepository` interface, `WatchItemEntity`, use cases (`ToggleWatchlistItemUseCase`, `GetWatchlistUseCase`).
- data/: Local data source, storage adapter, repository implementation, mappers if needed.
- presentation/: Providers (`watchlistProvider`), widgets (empty state), watchlist tab screen.

Why separate from market:

- Watchlist logic persists user intent; should not be tangled with fetch/display of market data.

Edge considerations:

- Duplicate coin IDs: prevent by set semantics.
- Missing coin in market feed: still show placeholder or remove automatically?
- Data migration if storage format changes (version key in box).

Testing focus:

- Repository: add/remove operations idempotency.
- Use case: toggling logic (added -> removed cycles).
- Widget: watchlist tab empty vs populated states.
