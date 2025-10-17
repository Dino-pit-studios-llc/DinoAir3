# features/market/presentation

Flutter UI & state management layer for the Market feature.

Include:

- screens/: `MarketScreen`, `CoinDetailScreen` (list + detail views)
- widgets/: Reusable UI parts (coin row, stat grid, time range chips, price change badge)
- providers/: Riverpod providers (e.g. `marketCoinsProvider`, `coinDetailProvider`)
- controllers/ or notifiers/: StateNotifier/AsyncNotifier classes that orchestrate use case calls
- view_models/ (optional): Lightweight UI-specific transformations (e.g. formatting numbers)

Why separate from domain & data:

- Keeps Flutter-dependent code isolated
- Encourages thin UI that delegates logic to providers + use cases
- Easier to write widget tests without pulling in data layer

Patterns:

- Use `AsyncValue` to represent loading/error/data states
- Convert domain entities into presentation-friendly formats as late as possible (inside widgets or a view model)

Testing:

- Widget tests with `ProviderScope(overrides: [...])` to inject fake providers
- Golden tests for `CoinRow`, `PriceChangeBadge`
