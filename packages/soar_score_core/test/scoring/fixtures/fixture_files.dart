import 'dart:convert';
import 'dart:io';

/// Loads a golden fixture file of the F5J profile.
///
/// The files are plain JSON in `test/fixtures/f5j`, so any other client or
/// offline library can run the same cases. Tests run from the package root.
List<Map<String, Object?>> loadF5jFixtures(String file) {
  final json = jsonDecode(File('test/fixtures/f5j/$file').readAsStringSync());
  return [for (final c in json as List) (c as Map).cast<String, Object?>()];
}

Map<String, Object?> asMap(Object? value) =>
    (value as Map).cast<String, Object?>();

List<Map<String, Object?>> asMaps(Object? value) => [
  for (final m in value as List) asMap(m),
];

double asDouble(Object? value) => (value as num).toDouble();
