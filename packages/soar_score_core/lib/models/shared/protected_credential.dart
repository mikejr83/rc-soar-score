import 'package:equatable/equatable.dart';

/// The protected form of an invitation credential.
///
/// It is a derived hash, never the raw credential, and it must not reach
/// logs or public output, so [toString] hides it. Read [value] only on the
/// sync and API path.
class ProtectedCredential extends Equatable {
  /// Wraps the protected string; throws [ArgumentError] when it is blank.
  ProtectedCredential(String value) : value = _requireNotBlank(value);

  /// The protected string.
  final String value;

  static String _requireNotBlank(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be blank');
    }
    return value;
  }

  @override
  String toString() => 'ProtectedCredential(<redacted>)';

  @override
  List<Object?> get props => [value];
}
