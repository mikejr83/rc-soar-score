import 'package:soar_score_core/services/sync/field_merge.dart';
import 'package:test/test.dart';

void main() {
  final base = {
    'name': 'Open',
    'site': 'Hill',
    'revision': 1,
    'updated_at': 'a',
  };

  test('changes to different fields are both kept', () {
    final merged = FieldMerge.merge(
      base: base,
      current: {...base, 'site': 'Ridge', 'revision': 2, 'updated_at': 'b'},
      submitted: {...base, 'name': 'Cup', 'updated_at': 'c'},
    );

    expect(merged, {
      'name': 'Cup',
      'site': 'Ridge',
      'revision': 2,
      'updated_at': 'c',
    });
  });

  test('the same field changed to different values is no merge', () {
    final merged = FieldMerge.merge(
      base: base,
      current: {...base, 'name': 'Mine', 'revision': 2},
      submitted: {...base, 'name': 'Yours'},
    );

    expect(merged, isNull);
  });

  test('the same field changed to the same value merges', () {
    final merged = FieldMerge.merge(
      base: base,
      current: {...base, 'name': 'Cup', 'revision': 2},
      submitted: {...base, 'name': 'Cup'},
    );

    expect(merged!['name'], 'Cup');
  });

  test('a removed field is removed from the result', () {
    final merged = FieldMerge.merge(
      base: base,
      current: {...base, 'revision': 2},
      submitted: {'name': 'Open', 'revision': 1, 'updated_at': 'a'},
    );

    expect(merged!.containsKey('site'), isFalse);
  });

  test('an older updated_at never replaces a newer one', () {
    final merged = FieldMerge.merge(
      base: base,
      current: {...base, 'site': 'Ridge', 'updated_at': 'z'},
      submitted: {...base, 'name': 'Cup', 'updated_at': 'b'},
    );

    expect(merged!['updated_at'], 'z');
  });
}
