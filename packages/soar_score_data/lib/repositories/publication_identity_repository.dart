import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Publication identities in the database; backend only, so written without a
/// mutation.
class PublicationIdentityRepository extends DriftRepository
    implements core.PublicationIdentityRepository {
  PublicationIdentityRepository(super.db, {super.stores});

  late final _store = store<core.PublicationIdentity>('PublicationIdentity');

  @override
  Future<core.PublicationIdentity?> findById(core.Id id) => _store.find(id);

  @override
  Future<core.PublicationIdentity?> findForContest(core.Id contestId) async {
    final found = await _store.whereId('contest_id', contestId, orderBy: 'id');
    return found.isEmpty ? null : found.first;
  }

  @override
  Future<List<core.PublicationIdentity>> listForOwner(
    core.Id ownerPublicProfileId,
  ) => _store.whereId(
    'owner_public_profile_id',
    ownerPublicProfileId,
    orderBy: 'id',
  );

  @override
  Future<List<core.PublicationIdentity>> listPublic(
    core.PublicationListQuery query,
  ) {
    final where = StringBuffer(
      "visibility = 'Public' AND published_at IS NOT NULL "
      'AND current_projection_id IS NOT NULL AND contest_starts_at IS NOT NULL',
    );
    final variables = <Variable>[];
    void contains(String column, String text) {
      final needle = text.trim();
      if (needle.isEmpty) return;
      where.write(" AND LOWER($column) LIKE ? ESCAPE '!'");
      variables.add(Variable<String>('%${_likeEscape(needle.toLowerCase())}%'));
    }

    contains('contest_name', query.name);
    // "Seattle, WA" finds a venue holding both parts, in any stored order.
    for (final part in query.venue.split(',')) {
      contains('venue', part);
    }
    final from = query.startsOnOrAfter;
    if (from != null) {
      where.write(' AND contest_starts_at >= ?');
      variables.add(Variable<String>(core.formatUtcTimestamp(from)));
    }
    final before = query.startsBefore;
    if (before != null) {
      where.write(' AND contest_starts_at < ?');
      variables.add(Variable<String>(core.formatUtcTimestamp(before)));
    }
    return _store.whereSql(
      where.toString(),
      variables,
      orderBy: 'contest_starts_at DESC, id',
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<int> countPublicActive({
    DateTime? startsOnOrAfter,
    DateTime? endsOnOrAfter,
    required DateTime startsBefore,
  }) {
    final where = StringBuffer(
      "visibility = 'Public' AND published_at IS NOT NULL "
      'AND contest_starts_at IS NOT NULL AND contest_starts_at < ?',
    );
    final variables = <Variable>[
      Variable<String>(core.formatUtcTimestamp(startsBefore)),
    ];
    if (startsOnOrAfter != null) {
      where.write(' AND contest_starts_at >= ?');
      variables.add(Variable<String>(core.formatUtcTimestamp(startsOnOrAfter)));
    }
    if (endsOnOrAfter != null) {
      where.write(' AND COALESCE(contest_ends_at, contest_starts_at) >= ?');
      variables.add(Variable<String>(core.formatUtcTimestamp(endsOnOrAfter)));
    }
    return _store.countWhere(where.toString(), variables);
  }

  /// Escapes `%`, `_` and the escape character `!` for a LIKE pattern.
  static String _likeEscape(String text) =>
      text.replaceAll('!', '!!').replaceAll('%', '!%').replaceAll('_', '!_');

  @override
  Future<core.PublicationIdentity> save(core.PublicationIdentity identity) =>
      db.transaction(() async {
        final stored = await _store.findJson(identity.id);
        final storedRevision = stored?['revision'] as int?;
        if (storedRevision != null && storedRevision != identity.revision) {
          throw core.StaleRevisionError(
            entityType: _store.entityType,
            entityId: identity.id,
            expectedRevision: identity.revision,
            storedRevision: storedRevision,
          );
        }
        final json = _store.encode(identity);
        json['revision'] = storedRevision == null
            ? identity.revision
            : storedRevision + 1;
        final saved = _store.decode(json);
        await _store.upsertJson(_store.encode(saved));
        return saved;
      });
}
