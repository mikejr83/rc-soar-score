import 'id.dart';

/// Example domain model for a contest.
///
/// This is a scaffold placeholder only: the full contest model —
/// configuration revisions, matrix, participation, scoring access,
/// publication, and the other independent control states defined in
/// `plan/architecture-requirements/data/contest.md` — is later work.
class Contest {
  Contest({
    required this.id,
    required String name,
    required DateTime startedAt,
  })  : name = name.trim(),
        startedAt = startedAt.toUtc() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
  }

  /// Stable opaque identifier for the contest.
  final Id id;

  /// Contest display name.
  final String name;

  /// Contest start time; always stored in UTC.
  final DateTime startedAt;

  @override
  bool operator ==(Object other) =>
      other is Contest &&
      other.id == id &&
      other.name == name &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(id, name, startedAt);

  @override
  String toString() => 'Contest(id: $id, name: $name, startedAt: $startedAt)';
}
