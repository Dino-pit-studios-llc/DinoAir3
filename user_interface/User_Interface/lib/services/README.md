# lib/services

Horizontal technical services reused across multiple features.

Examples (planned):

- api/: HTTP client wrappers, interceptors, networking utilities
- cache/: Generic caching helpers (in-memory, TTL management)
- persistence/: Shared storage helpers not tied to a single feature
- logging/: (Optional) central logging abstractions

Why separate from `core/`:

- `core/` holds passive primitives (pure utilities, constants). `services/` may manage lifecycle, I/O, or state.

Principles:

- Keep feature awareness out; features depend on services (one-way).
- Expose small interfaces for testability (e.g. `AbstractHttpClient`).

Do NOT put:

- Business/domain logic (belongs in feature domain layer).
- UI concerns.
