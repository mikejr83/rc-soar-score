import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../sync/sql_placeholders.dart';

/// The `entity_type` of the audit event that marks an inspection owner.
const inspectionOwnerEntityType = 'InspectionOwner';

/// The inspection owners a database holds.
///
/// An inspection owner is an id that owns every row of the contests imported
/// "for inspection" from one person. It is neither the Local account nor any
/// signed-in account, so the rows are never synced and never claimed. The
/// owner is recognised by a durable marker: one `AuditEvent` (action
/// `Restoration`, entity type `InspectionOwner`, entity id the owner) written
/// in the same transaction as the rows it describes, so the marker cannot be
/// lost without the data. Markers are not in the sync catalog.
///
/// A marker has no contest, and an imported file may only bring audit events
/// of its own contest (and refuses this entity type outright), so a file
/// cannot make an account id look like an inspection owner.
class InspectionOwnerSet {
  const InspectionOwnerSet(this._identities);

  /// No owner is recognised.
  static const empty = InspectionOwnerSet({});

  final Map<String, Set<String>> _identities;

  /// Every recognised owner id.
  Set<String> get ownerIds => _identities.keys.toSet();

  bool contains(core.Id? owner) =>
      owner != null && _identities.containsKey(owner.value);

  bool get isEmpty => _identities.isEmpty;

  /// The ids that name the people [owner] stands for (the source account and
  /// its Local account), or none.
  Set<String> identitiesOf(String owner) => _identities[owner] ?? const {};

  /// The owner whose identities intersect [identities], if any. The same
  /// installation before and after sign-in, and two exports from one account,
  /// meet in one owner.
  String? ownerFor(Set<String> identities) {
    for (final MapEntry(:key, :value) in _identities.entries) {
      if (value.any(identities.contains)) return key;
    }
    return null;
  }
}

/// Reads the inspection owner markers of [db].
class InspectionOwnerMarkers {
  InspectionOwnerMarkers(this._db);

  final SoarScoreDatabase _db;

  /// The recognised owners, from the markers. Throws when the audit events
  /// cannot be read; callers that guard syncing treat that as "unknown".
  Future<InspectionOwnerSet> load() async {
    final rows = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT entity_id, reason FROM audit_events '
            "WHERE entity_type = ? AND action = 'Restoration' "
            'AND contest_id IS NULL AND owner_account_id = entity_id '
            'ORDER BY server_timestamp, id',
          ),
          variables: [Variable<String>(inspectionOwnerEntityType)],
          readsFrom: {_db.auditEvents},
        )
        .get();
    final identities = <String, Set<String>>{};
    for (final row in rows) {
      final owner = row.read<String>('entity_id');
      final set = identities.putIfAbsent(owner, () => <String>{});
      final reason = row.readNullable<String>('reason');
      if (reason == null) continue;
      try {
        if (jsonDecode(reason) case {'identities': final List list}) {
          set.addAll(list.whereType<String>());
        }
      } on FormatException {
        // A marker with unreadable detail still marks its owner.
      }
    }
    return InspectionOwnerSet(identities);
  }

  /// Whether [owner] has a marker. A targeted read, so a caller that only
  /// needs one answer does not load every marker. Throws when the audit
  /// events cannot be read.
  Future<bool> isMarked(core.Id owner) async {
    final row = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT 1 AS found FROM audit_events '
            "WHERE entity_type = ? AND action = 'Restoration' "
            'AND contest_id IS NULL AND owner_account_id = entity_id '
            'AND entity_id = ? LIMIT 1',
          ),
          variables: [
            Variable<String>(inspectionOwnerEntityType),
            Variable<String>(owner.value),
          ],
          readsFrom: {_db.auditEvents},
        )
        .getSingleOrNull();
    return row != null;
  }

  /// The audit event row that marks [owner] as the inspection owner of
  /// [identities], for [contestId] imported from [source].
  static Map<String, Object?> markerRow({
    required core.Id owner,
    required Set<String> identities,
    required DateTime at,
    required core.Id contestId,
    String? sourceLabel,
    String? exportedAt,
    String? sourceInstallationId,
    String? fileName,
  }) => {
    'id': core.Id.create().value,
    'entity_type': inspectionOwnerEntityType,
    'entity_id': owner.value,
    'contest_id': null,
    'owner_account_id': owner.value,
    'publication_id': null,
    'action': 'Restoration',
    'actor_id': null,
    'authority': 'System',
    'installation_id': null,
    'device': null,
    'base_revision': null,
    'resulting_revision': null,
    'server_timestamp': at.toUtc().toIso8601String(),
    'client_timestamp': at.toUtc().toIso8601String(),
    'reason': jsonEncode({
      'identities': (identities.toList()..sort()),
      'source_label': sourceLabel,
      'exported_at': exportedAt,
      'source_installation_id': sourceInstallationId,
      'file_name': fileName,
      'contest_id': contestId.value,
    }),
    'outcome': 'Success',
  };
}
