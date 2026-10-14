import 'json_equality.dart';

/// Three-way merge of two changes to one entity, field by field.
///
/// The service merges only when the two changes touched different fields. It
/// never picks a winner for a field both changed to different values: that is
/// a conflict for the director.
abstract final class FieldMerge {
  /// Fields the service maintains itself; they never count as a change.
  static const bookkeeping = {'revision', 'updated_at'};

  /// The entity with [submitted]'s changes applied on top of [current], or
  /// null when both changed the same field to different values.
  ///
  /// [base] is the entity at the revision [submitted] was made on, and
  /// [current] is what the service holds now.
  static Map<String, Object?>? merge({
    required Map<String, Object?> base,
    required Map<String, Object?> current,
    required Map<String, Object?> submitted,
  }) {
    final mine = _changed(base, submitted);
    final theirs = _changed(base, current);
    final merged = {...current};
    for (final field in mine) {
      final overlaps = theirs.contains(field);
      if (overlaps && !jsonEquals(submitted[field], current[field])) {
        return null;
      }
      if (submitted.containsKey(field)) {
        merged[field] = submitted[field];
      } else {
        merged.remove(field);
      }
    }
    final stamp = submitted['updated_at'];
    final held = current['updated_at'];
    if (stamp is String && (held is! String || stamp.compareTo(held) > 0)) {
      merged['updated_at'] = stamp;
    }
    return merged;
  }

  static Set<String> _changed(
    Map<String, Object?> from,
    Map<String, Object?> to,
  ) => {
    for (final key in {...from.keys, ...to.keys})
      if (!bookkeeping.contains(key) && !jsonEquals(from[key], to[key])) key,
  };
}
