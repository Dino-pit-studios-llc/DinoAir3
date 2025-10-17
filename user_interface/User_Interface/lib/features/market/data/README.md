# features/market/data

Implements the repository contract using concrete data sources and mapping logic.

Includes:

- dto/: Raw models mirroring external API JSON (e.g. `CoinDto`, `CoinDetailDto`).
- sources/: Remote (API) + local (cache/offline) data source classes.
- mappers/: Functions/extensions converting DTO -> Domain Entity (& reverse if needed).
- repositories/: `MarketRepositoryImpl` bridging domain and data sources.
- adapters/ (optional): HTTP interceptors, response transformers.

Why separate from domain:

- External API fields/naming can change without leaking into domain.
- Easier to test mapping in isolation.

Guidelines:

- Keep DTOs `@immutable` and add `fromJson/toJson` (use json_serializable eventually).
- No Flutter imports here; rely on `dio`, `meta`, `collection` etc. only.
- Fail fast: throw internal exceptions (mapped to Failures higher up) when required fields are missing.

Testing:

- Unit tests for mappers (DTO -> Entity).
- Repository test with fake data sources.

Checklist refs: (D2) API client integration, (D4) DTOs, (D5) mappers, (D6) implementation, (D9) cache policy.
