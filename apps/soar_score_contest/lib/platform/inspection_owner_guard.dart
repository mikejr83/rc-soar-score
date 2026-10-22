import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// Answers whether an owner id is an inspection owner: the owner of a
/// contest imported "for inspection", whose data must never leave this
/// installation.
///
/// Positive answers are kept. A negative answer is kept too: an inspection
/// owner is a fresh id made by an import (or an earlier one, reused), never
/// an account id that was seen before, so an id that was not an inspection
/// owner never becomes one. An unreadable marker table is not cached; the
/// caller sees the error and must fail closed.
class InspectionOwnerGuard {
  InspectionOwnerGuard(SoarScoreDatabase database)
    : _markers = InspectionOwnerMarkers(database);

  final InspectionOwnerMarkers _markers;
  final _inspection = <String>{};
  final _accounts = <String>{};

  /// Whether [owner] is an inspection owner. `null` is not. Throws when the
  /// markers cannot be read.
  Future<bool> isInspection(core.Id? owner) async {
    if (owner == null) return false;
    if (_inspection.contains(owner.value)) return true;
    if (_accounts.contains(owner.value)) return false;
    final marked = await _markers.isMarked(owner);
    (marked ? _inspection : _accounts).add(owner.value);
    return marked;
  }

  /// Every inspection owner now in the database.
  Future<Set<core.Id>> owners() async {
    final owners = (await _markers.load()).ownerIds;
    _inspection.addAll(owners);
    return {for (final owner in owners) core.Id.parse(owner)};
  }

  /// Forgets what was learned, after owners were added or removed.
  void changed() {
    _inspection.clear();
    _accounts.clear();
  }
}
