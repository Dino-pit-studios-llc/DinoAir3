# lib/app

Top-level application wiring: root widget (`MyApp`), routing configuration, Provider/Riverpod scope entry, theming, and high-level scaffolds.

What goes here:

- `app.dart` (root widget building `MaterialApp` or `MaterialApp.router`).
- Route configuration (manual `onGenerateRoute`, or `go_router` if adopted later).
- Theme builders & theme extensions wiring.
- Global observers (e.g. Riverpod `ProviderObserver`, route observers, navigator key).
- App-level initialization logic that belongs after bootstrap (dynamic theme load, persisted settings fetch, etc.).

Why separate from `main.dart`:

- `main.dart` stays minimal (delegates to bootstrap then constructs `MyApp`).
- Easier to test root widget in isolation.

Do NOT put:

- Business logic (belongs in `features/*`).
- Low-level API code (belongs in `services/api`).

Next steps (Checklist refs):

- (A6) Implement theming and semantic colors, attach to `ThemeData`.
- (A7) Add routing approach.
- (F19) Theme toggle surface once Settings feature appears.

Testing guidance:

- Widget test for root building correct theme & initial route.
