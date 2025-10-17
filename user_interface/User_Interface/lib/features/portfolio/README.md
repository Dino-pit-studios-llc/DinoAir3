# features/portfolio

Tracks the user's holdings and computes portfolio metrics.

Responsibilities:

- Persist holdings (coinId, amount, avg buy price) locally.
- Compute derived values: current value, total cost basis, unrealized P/L, allocation percentages.
- Provide summary entity (total value, pnl %, top allocations) to UI.
- Support add/edit/remove holding flows (F15-F18).

Subfolders to add:

- domain/: Entities (`HoldingEntity`, `PortfolioSummaryEntity`), repository interface, use cases (`AddHoldingUseCase`, `RemoveHoldingUseCase`, `ComputePortfolioUseCase`).
- data/: Local persistence (Hive box / shared prefs JSON), mappers, repository implementation.
- presentation/: Portfolio tab screen, add/edit holding bottom sheet, providers for holdings & summary.

Why separate:

- Math/business rules evolve independently of UI styling or storage mechanism.

Edge considerations:

- Rounding of decimal amounts (crypto often high precision) — consider Decimal package later if doubles cause drift.
- Handling delisted coins — stale holdings should still appear with last known price or flagged missing.
- Performance: recompute summary only when holdings or price feed change (memoize). (Q3)

Testing focus:

- Deterministic unit tests for portfolio calculations (T2).
