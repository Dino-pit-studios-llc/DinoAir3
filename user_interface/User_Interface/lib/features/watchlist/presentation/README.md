# features/watchlist/presentation

UI + state layer for Watchlist feature.

Include:

- screen/: `WatchlistScreen` rendering either empty state or list
- widgets/: `WatchlistEmptyState`, `WatchlistCoinTile`
- providers/: Riverpod providers (`watchlistProvider` exposing AsyncValue<List<WatchItemEntity>>`or just`List<String>` coin IDs)
- controllers/: Notifier handling toggle logic via use cases

Patterns:

- UI watches market coin list + watchlist IDs to highlight favorites
- Toggling triggers use case; optimistic update can improve perceived speed

Testing:

- Widget test: empty vs populated
- Provider test: toggling adds/removes idempotently
