# services/api

Networking layer abstractions and HTTP tooling shared across features.

Planned components (D2):

- `coin_api_client.dart`: High-level client exposing typed methods (e.g. `fetchTopCoins(limit)`)
- `rest_client.dart`: Thin wrapper around Dio (or http) to centralize base URL, interceptors, retry, timeouts
- interceptors/: Logging, rate-limit (simple delay/backoff), error mapping
- models/: Generic response wrappers (e.g. paginated) if API supplies them

Why separate from feature data layers:

- Provides reusable HTTP utilities (timeout, headers, error translation) without coupling to a single feature
- Feature repositories depend on `CoinApiClient` rather than raw Dio

Error handling:

- Catch DioError -> map to internal exceptions -> later converted to `Failure` in core/errors

Testing:

- Use Dio's `MockAdapter` (or custom adapter) to simulate responses
