# features/watchlist/data

Concrete persistence & data adaptation for Watchlist.

Include:

- local/ : Storage adapter (Hive box or SharedPreferences wrapper)
- models/ : If you need a model distinct from domain entity (often domain entity is simple enough to store directly)
- repository/ : `WatchlistRepositoryImpl` implementing domain interface

Responsibilities:

- Persist coin IDs with timestamp added
- Provide fast lookup (set semantics) to avoid duplicates
- Optionally expose a stream for reactive updates

Why separate:

- Isolates storage decisions from domain logic
- Allows easy migration (e.g. SharedPreferences -> Hive) without changing domain

Testing:

- Use in-memory fake/Hive test box to validate add/remove/toggle behaviors
