import 'dart:io';
import 'dart:typed_data';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../server/embedded_server.dart';
import '../server/profile_access.dart';
import '../services/exchange/contest_exchange.dart';

/// Exports and imports contests of the embedded server's database.
class NativeContestExchange implements ContestExchange {
  NativeContestExchange(this._server, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final EmbeddedServer _server;
  final DateTime Function() _clock;

  @override
  Future<ExchangeExport> export(core.Id contestId, {required bool redact}) =>
      _guard(() async {
        final database = _server.database;
        final contest = await _server.repository.contestRepository.findById(
          contestId,
        );
        final file = await ContestExporter(database, clock: _clock).export(
          contestId,
          redact: redact,
          source: ExportSource(
            label: Platform.localHostname,
            diagnostics: {
              'platform': Platform.operatingSystem,
              'platform_version': Platform.operatingSystemVersion,
            },
          ),
        );
        return ExchangeExport(
          fileName: '${_safeName(contest?.name ?? 'contest')}.rcsoar',
          bytes: Uint8List.fromList(file.encode()),
        );
      });

  @override
  Future<ExchangePreview> preview(Uint8List bytes) => _guard(() async {
    final file = ExchangeFile.decode(bytes);
    final preview = await ContestImporter(
      _server.database,
      clock: _clock,
    ).preview(file, target: _target);
    return ExchangePreview(
      contestName: preview.header.contestName,
      sourceLabel: preview.header.sourceLabel,
      exportedAt:
          DateTime.tryParse(preview.header.exportedAt)?.toUtc() ??
          _clock().toUtc(),
      redacted: preview.redacted,
      counts: preview.counts,
      refusals: [for (final r in preview.refusals) r.message],
      available: [for (final m in preview.availableModes) _modeOf(m)],
      unavailable: {
        for (final mode in ImportMode.values)
          _modeOf(mode):
              ?(preview.unavailableModes[mode] ??
              _modeRefusal(preview.modeRefusals[mode])),
      },
      existingCopyName: preview.existingCopyName,
    );
  });

  @override
  Future<ExchangeImported> import(
    Uint8List bytes,
    ExchangeImportMode mode, {
    String? fileName,
  }) => _guard(() async {
    final result = await ContestImporter(_server.database, clock: _clock)
        .import(
          ExchangeFile.decode(bytes),
          mode: mode == ExchangeImportMode.inspection
              ? ImportMode.inspection
              : ImportMode.editable,
          target: _target,
          fileName: fileName,
        );
    _server.inspectionOwners.changed();
    return ExchangeImported(
      contestId: result.contestId,
      mode: mode,
      differences: result.differences.length,
      recalculationNote: result.recalculationNote,
    );
  });

  @override
  Future<Set<core.Id>> inspectionContests() =>
      _server.runProfileOperation(() async {
        final owners = await _server.inspectionOwners.owners();
        if (owners.isEmpty) return <core.Id>{};
        final contests = await _server.repository.contestRepository.getAll();
        return {
          for (final contest in contests)
            if (owners.contains(contest.ownerAccountId)) contest.id,
        };
      });

  ImportTarget get _target {
    final acting = _server.actingAccountId;
    final local = _server.localAccountId;
    return ImportTarget(
      localAccountId: local,
      signedInAccountId: acting == local ? null : acting,
    );
  }

  static ExchangeImportMode _modeOf(ImportMode mode) => switch (mode) {
    ImportMode.inspection => ExchangeImportMode.inspection,
    ImportMode.editable => ExchangeImportMode.editable,
  };

  static String? _modeRefusal(List<ImportRefusal>? refusals) =>
      refusals == null || refusals.isEmpty
      ? null
      : refusals.map((r) => r.message).join(' ');

  static String _safeName(String name) {
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '').trim();
    return safe.isEmpty ? 'contest' : safe;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await _server.runProfileOperation(body);
    } on ProfileUnavailableError catch (e) {
      throw ExchangeFailure(e.message);
    } on ExchangeException catch (e) {
      throw ExchangeFailure(e.message);
    } on FormatException catch (e) {
      throw ExchangeFailure('The file could not be read: ${e.message}');
    }
  }
}
