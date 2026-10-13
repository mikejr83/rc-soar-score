/// The slice of the Windows registry the URL scheme registration needs, so the
/// registration logic can be tested without a registry.
abstract class RegistryStore {
  /// The string value [name] of the key at [keyPath] (under the current user's
  /// hive), or `null` when the key or value does not exist. An empty [name] is
  /// the key's default value.
  String? getString(String keyPath, String name);

  /// Writes the string value [name] of the key at [keyPath], creating the key
  /// when missing.
  void setString(String keyPath, String name, String value);
}
