import 'indexed_db_local_ui_backend.dart';
import 'local_ui_backend.dart';

/// The browser's IndexedDB; [directory] is ignored.
Future<LocalUiBackend> openPlatformBackend({String? directory}) =>
    IndexedDbLocalUiBackend.open();
