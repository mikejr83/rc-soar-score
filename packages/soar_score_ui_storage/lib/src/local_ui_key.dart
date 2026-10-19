/// A typed name for one piece of UI-only state.
///
/// [version] is the shape of the stored value. A value stored under another
/// version, or one [decode] cannot read, reads as [defaultValue]; bump it when
/// the encoded shape changes incompatibly.
class LocalUiKey<T> {
  const LocalUiKey({
    required this.name,
    required this.defaultValue,
    required this.encode,
    required this.decode,
    this.version = 1,
    this.unreadable,
  });

  /// Stable, unique name of the key within an account, such as `theme_mode`.
  final String name;

  /// What a read gives when nothing usable is stored.
  final T defaultValue;

  /// What a read gives when something is stored but cannot be used: damaged
  /// text, another version, or data [decode] rejects. `null` means
  /// [defaultValue], so the damage is invisible; give a value to tell the
  /// caller that stored data exists but is unreadable.
  final T Function()? unreadable;

  /// The schema version of the encoded value.
  final int version;

  /// Turns a value into JSON-encodable data (numbers, strings, booleans,
  /// lists and string-keyed maps of those).
  final Object? Function(T value) encode;

  /// Turns data from [encode] back into a value; may throw on data it does
  /// not understand, which reads as [defaultValue].
  final T Function(Object? data) decode;
}
