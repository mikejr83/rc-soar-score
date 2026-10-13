import 'package:win32_registry/win32_registry.dart';

import 'registry_store.dart';

/// [RegistryStore] over the current user's registry hive (`HKEY_CURRENT_USER`),
/// so nothing here needs administrator rights.
class Win32RegistryStore implements RegistryStore {
  const Win32RegistryStore();

  @override
  String? getString(String keyPath, String name) {
    RegistryKey? key;
    try {
      key = CURRENT_USER.open(keyPath);
      return key.getString(name);
    } on Object {
      // The key does not exist (or cannot be read): treat as not registered.
      return null;
    } finally {
      key?.close();
    }
  }

  @override
  void setString(String keyPath, String name, String value) {
    final key = CURRENT_USER.create(keyPath);
    try {
      key.setValue(name, RegistryValue.string(value));
    } finally {
      key.close();
    }
  }
}
