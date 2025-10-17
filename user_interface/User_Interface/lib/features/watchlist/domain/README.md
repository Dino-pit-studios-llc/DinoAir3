# features/watchlist/domain

Domain layer for Watchlist feature.

Include:

- Entities: `WatchItemEntity` (coinId, addedAt)
- Repository interface: `WatchlistRepository` (methods: getAll, toggle, add, remove, exists)
- Use cases: `GetWatchlistUseCase`, `ToggleWatchlistItemUseCase`, `AddWatchItemUseCase`, `RemoveWatchItemUseCase`

Guidelines:

- Pure Dart, no Flutter or storage APIs.
- Keep methods synchronous unless delegated repository returns Future.

Edge cases:

- Toggling an item that does not exist vs removing.
- Handling duplicates (repository should de-duplicate by coinId).
