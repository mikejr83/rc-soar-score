# UI Storage Package Agent Guide

A typed, per-account key-value store for UI-only state on the client: theme, hidden panels, the New Contest draft. Native keeps it in SQLite, web in IndexedDB. Never synced. Pure Dart.

## Structure

- `lib/soar_score_ui_storage.dart` — the public library; consumers import only this
- `lib/src/local_ui_store.dart` — the `LocalUiStore` contract (get, set, remove, watch); `local_ui_key.dart` — `LocalUiKey<T>` (name, default, version, encode, decode)
- `lib/src/local_ui_backend.dart` — raw string storage contract; `memory_`, `sqlite_` and `indexed_db_local_ui_backend.dart` implement it
- `lib/src/backend_local_ui_store.dart` — the store over any backend: account namespacing, version envelope, error swallowing, `watch`
- `lib/src/open_local_ui_store.dart` — opens the platform store (`open_native.dart` or `open_web.dart` by conditional import) and falls back to memory

## Boundaries

- **Contest data never goes through this package.** Contest entities live in `soar_score_data` and sync; this is for UI-only state.
- Depends on nothing in the monorepo. The native backend lives in its own SQLite file (`soar_score_ui.db`), so a contest data reset never clears UI state (decided in #319; the default is that it must not).
- Keys are namespaced by account id; the Local account is an account like any other.
- Calls never throw into the UI: a failed read gives the key's default, a failed write returns `false`; both are logged. Bump a key's `version` when its encoded shape changes; older values then read as the default. A key may set `unreadable` to tell stored-but-unusable data (damaged text, another version, a rejected decode) from nothing stored; without it both read as the default.
- The barrel does not export `SqliteLocalUiBackend` or `IndexedDbLocalUiBackend`; use `openLocalUiStore` so the web build compiles no SQLite and the native build no `package:web`.

## Testing

- `dart test` runs the contract suite (`test/support/local_ui_store_contract.dart`) against the in-memory and SQLite backends.
- The same suite runs against IndexedDB in a browser: `dart test -p chrome test/indexed_db_local_ui_store_test.dart` (needs Chrome; set `CHROME_EXECUTABLE`). `melos test` skips it because it is `@TestOn('browser')`.
