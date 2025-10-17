# features/portfolio/data

Concrete storage + mapping for portfolio holdings.

Include:

- local/: Persistence adapter (Hive box name e.g. `holdings_box`) storing holdings records
- models/: Storage model if distinct from domain entity (e.g. to include createdAt/updatedAt metadata)
- repository/: `PortfolioRepositoryImpl` bridging persistence + pricing input (may accept a price provider)
- mappers/: Transform storage model <-> domain entity if needed

Responsibilities:

- Durable storage of holdings
- Efficient read of all holdings (likely small list)
- Provide stream/watch API for reactive UI updates

Separation rationale:

- Changing storage (Hive -> Isar) does not impact domain/tests using repository interface

Edge concerns:

- Concurrency: avoid overwriting modifications by reading-modifying-writing without locking (serialize writes)
- Precision: persist numeric values at sufficient precision (e.g. as string or int micro-units)

Testing:

- Use in-memory / temp directory Hive for add-update-remove lifecycle
