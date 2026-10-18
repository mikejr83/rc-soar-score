/// Local UI storage: a typed, per-account key-value store for UI-only state.
///
/// Native builds keep it in SQLite, web builds in IndexedDB. Contest data never
/// goes through it.
library;

export 'src/backend_local_ui_store.dart';
export 'src/local_ui_backend.dart';
export 'src/local_ui_key.dart';
export 'src/local_ui_store.dart';
export 'src/memory_local_ui_backend.dart';
export 'src/open_local_ui_store.dart';
