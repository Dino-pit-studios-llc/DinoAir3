# features/portfolio/presentation

UI + state management for the Portfolio feature.

Include:

- screen/: `PortfolioScreen` (tab root with summary + holdings list)
- widgets/: `PortfolioSummaryCard`, `PortfolioHoldingTile`, `EditHoldingSheet`
- providers/: `portfolioHoldingsProvider`, `portfolioSummaryProvider`, `portfolioController`
- controllers/: `PortfolioController` invoking use cases (add/update/remove)

Patterns:

- Compute summary in provider: watch holdings + market prices provider (dependency injection via provider listen).
- Use `AsyncValue` if persistence or price lookup is async.

Edge cases:

- Empty holdings -> show onboarding / add holding call-to-action.
- Large number of holdings -> consider virtualization (rare for MVP).

Testing:

- Widget test: summary displays correct total value with mocked data.
- Provider test: summary recalculates when holdings or price map changes.
