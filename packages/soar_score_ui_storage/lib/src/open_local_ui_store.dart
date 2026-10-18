import 'package:logging/logging.dart';

import 'backend_local_ui_store.dart';
import 'local_ui_store.dart';
import 'memory_local_ui_backend.dart';
import 'open_native.dart' if (dart.library.js_interop) 'open_web.dart';

final _logger = Logger('LocalUiStore');

/// Opens the platform's store: SQLite in [directory] on native, IndexedDB on
/// web (where [directory] is ignored).
///
/// Never throws: when the storage cannot be opened it logs and returns a store
/// that keeps values in memory for this run, so the UI falls back to defaults.
Future<LocalUiStore> openLocalUiStore({String? directory}) async {
  try {
    return BackendLocalUiStore(await openPlatformBackend(directory: directory));
  } catch (error, stackTrace) {
    _logger.warning(
      'Cannot open local UI storage; using memory',
      error,
      stackTrace,
    );
    return BackendLocalUiStore(MemoryLocalUiBackend());
  }
}
