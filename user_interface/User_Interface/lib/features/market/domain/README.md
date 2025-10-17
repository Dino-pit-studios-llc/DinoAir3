# features/market/domain

Pure business logic abstractions for the Market feature.

Include here:

- Entities: Immutable, framework-agnostic representations (e.g. `CoinEntity`, `CoinDetailEntity`, `PricePointEntity`).
- Repository interfaces: `abstract class MarketRepository { ... }` describing operations without implementation details.
- Use cases (a.k.a. interactors): Small classes/functions encapsulating a single action (e.g. `GetTopCoinsUseCase`, `GetCoinDetailUseCase`). Keep them thin: validate inputs, delegate to repository.
- Value objects (optional): E.g. `TimeRange` enum, `Currency` enum.

Why isolate domain:

- Maximum testability (no Flutter, no HTTP, no JSON dependencies).
- Stable contract: UI & data source layers can evolve independently.

Guidelines:

- No imports from `flutter` or `dio`.
- Avoid leaking external naming (e.g. API field names) — map them in data layer first.
- Keep synchronous when possible; async only where needed for repository calls.

Testing:

- Unit test each use case in isolation with a mocked repository.
