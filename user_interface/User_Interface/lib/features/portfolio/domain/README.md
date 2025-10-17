# features/portfolio/domain

Domain definitions for portfolio calculations.

Include:

- Entities: `HoldingEntity` (coinId, amount, avgBuyPrice), `PortfolioSummaryEntity` (totalValue, totalCost, pnlAbs, pnlPct, allocations)
- Value objects: `Allocation` (coinId, percent, value) or simple map
- Repository interface: `PortfolioRepository` (getHoldings, add, update, remove, watchHoldings)
- Use cases: `AddHoldingUseCase`, `UpdateHoldingUseCase`, `RemoveHoldingUseCase`, `ComputePortfolioUseCase`

Guidelines:

- Keep monetary math precise (consider using int satoshi-like units or Decimal later if drift appears)
- Pure business logic only; no Flutter dependencies

Edge cases:

- Zero amount holdings should auto-remove or be filtered
- Division by zero when computing percentage (handle total cost/value == 0)

Testing:

- Deterministic tests for allocation percentages & pnl calculations
