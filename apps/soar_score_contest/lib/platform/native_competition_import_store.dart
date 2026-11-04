import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart'
    show Principal;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../server/embedded_server.dart';
import '../services/competition_import/competition_import.dart';
import '../services/new_contest/time_zones.dart';
import 'native_pilot_import_store.dart';

/// Writes imported GliderScore competitions into the embedded server's
/// database, owned by the account the installation acts as.
class NativeCompetitionImportStore extends NativePilotImportStore
    implements CompetitionImportStore {
  NativeCompetitionImportStore(this._server, {super.clock, this.timeZone})
    : super(_server);

  /// The version of the importer, stamped on every row it writes.
  static const toolVersion = '1.0.0';

  final EmbeddedServer _server;

  /// The zone of imported contests; this device's when null.
  final String? timeZone;

  core.ImportOwner get _owner =>
      core.ImportOwner(signedInAccountId: _server.actingAccountId);

  core.MutationMetadata _metadata(String kind) =>
      Principal(accountId: _server.actingAccountId).mutationMetadata(
        clientMutationId: 'gliderscore-$kind-${core.Id.create().value}',
        clientTime: clock().toUtc(),
      );

  @override
  Future<String> fingerprint(String path) async {
    final file = File(path);
    final name = path.split(RegExp(r'[\\/]')).last;
    final digest = await sha256.bind(file.openRead()).first;
    // The file name is part of the fingerprint (ADR 0006).
    final named = sha256.convert([...digest.bytes, ...name.codeUnits]);
    return 'sha256:$named';
  }

  @override
  Future<void> stampProfiles({
    required core.Id operationId,
    required String fingerprint,
    required List<core.ProfileStampEntry> entries,
  }) => _server.repository.contestImportRepository.stampProfiles(
    core.ProfileStampPlan(
      owner: _owner,
      importOperationId: operationId,
      fileFingerprint: fingerprint,
      toolVersion: toolVersion,
      entries: entries,
    ),
    metadata: _metadata('stamps'),
  );

  @override
  Future<core.CompetitionImportResult> importCompetition({
    required core.ContestImportDraft draft,
    required Map<int, core.Id> profileIds,
    required core.Id operationId,
    required String fingerprint,
  }) => _server.repository.contestImportRepository.importCompetition(
    core.CompetitionImportPlan(
      draft: draft,
      profileIds: profileIds,
      owner: _owner,
      timezone: timeZone ?? TimeZones.device(),
      importOperationId: operationId,
      fileFingerprint: fingerprint,
      toolVersion: toolVersion,
    ),
    metadata: _metadata('contest'),
  );

  @override
  Future<core.DrawImportTarget> drawTarget({
    required int compNo,
    required String fingerprint,
  }) => _server.repository.contestImportRepository.drawTarget(
    _owner,
    compNo,
    fingerprint,
  );

  @override
  Future<core.DrawImportResult> importDraw({
    required core.DrawImportDraft draft,
    required core.Id contestId,
    required core.Id operationId,
    required String fingerprint,
  }) => _server.repository.contestImportRepository.importDraw(
    core.DrawImportPlan(
      draft: draft,
      contestId: contestId,
      owner: _owner,
      importOperationId: operationId,
      fileFingerprint: fingerprint,
      toolVersion: toolVersion,
    ),
    metadata: _metadata('draw'),
  );

  @override
  Future<core.ImportedContestNote?> noteFor(core.Id contestId) async =>
      core.ImportedContestNote.fromStamps(
        await _server.repository.importProvenanceRepository.listForContest(
          contestId,
        ),
      );
}
