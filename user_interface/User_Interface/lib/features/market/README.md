# features/market

The Market feature surfaces a list of top cryptocurrencies and coin detail views.

Subdirectories:

- domain/: Core business abstractions (entities, repository contract, use cases) independent of Flutter or data formats.
- data/: External representations & bridging logic (DTO models, API + cache data sources, repository implementation, mappers).
- presentation/: Flutter layer (providers, notifiers, screens, widgets, UI-only models).

Data flow (read):
UI Widget -> Provider/Notifier -> UseCase -> Repository (interface) -> Data sources (remote/cache) -> DTO -> Mapper -> Entity -> Back to Provider State -> Rebuild UI.

Key responsibilities:

- Provide paginated or ranked list of coins with price & 24h change.
- Fetch and normalize coin detail (supply, market cap, volume, sparkline data for charts).
- Cache last successful response to enable offline snapshot (F22).

Separation rationale:

- Domain stays testable and stable even if API or UI changes.
- Presentation can iterate quickly without forcing refactors deeper in the stack.
- Data layer isolates third-party API quirks (naming, types, missing fields).

Add later (Checklist refs):

- (A9) Entities like `CoinEntity`, `CoinDetailEntity`.
- (A10) `MarketRepository` interface in domain.
- (F2) `GetTopCoinsUseCase`.
- (F3) Provider exposing `AsyncValue<List<CoinEntity>>`.
- (F9) Historical prices use case + chart provider.

Testing guidance:

- Domain: pure unit tests for use cases.
- Data: repository tests with mocked `CoinApiClient` and fake cache.
- Presentation: widget tests for list & loading/error states.
