import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/participants/participant_countries.dart';
import 'package:soar_score_contest/services/participants/participant_storage.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';

void main() {
  test('says nothing before the engine has looked at the scope', () {
    expect(ParticipantStorage.of(null), isNull);
    expect(ParticipantStorage.of(const SyncScopeSummary()), isNull);
  });

  test('pending or unbacked changes are local only', () {
    expect(
      ParticipantStorage.of(const SyncScopeSummary(pendingChanges: 1)),
      ParticipantStorage.localOnly,
    );
    expect(
      ParticipantStorage.of(const SyncScopeSummary(localOnly: true)),
      ParticipantStorage.localOnly,
    );
  });

  test('a synced scope with nothing pending is synced', () {
    expect(
      ParticipantStorage.of(SyncScopeSummary(lastSyncedAt: DateTime.utc(2026))),
      ParticipantStorage.synced,
    );
  });

  test('a typed country uses the list spelling when it matches', () {
    expect(normalizeCountry(' united states '), 'United States');
    expect(normalizeCountry('Narnia'), 'Narnia');
  });
}
