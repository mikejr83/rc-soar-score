import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'import_provenance.g.dart';

/// Where an imported contest, participation or profile came from.
///
/// One source-neutral row per stamped entity (see
/// `docs/adr/0006-gliderscore-import-persistence.md`). It never changes how
/// the entity behaves, is never edited, and is never used for matching. It is
/// director data: every row carries the importing director's account, and the
/// rows of a contest or its participations also carry the contest so an
/// export and a contest delete find them. See
/// `plan/data-model/entities/import_provenance.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ImportProvenance extends Equatable implements Synchronizable {
  ImportProvenance({
    required this.id,
    required this.ownerAccountId,
    this.contestId,
    required String stampedEntityType,
    required this.stampedEntityId,
    required String sourceSystem,
    required Map<String, Object?> sourceKeys,
    Map<String, Object?>? sourceValues,
    required String fileFingerprint,
    this.dedupeKey,
    required this.importOperationId,
    required String toolVersion,
    required DateTime importedAt,
    this.revision = 0,
  }) : stampedEntityType = requireNotBlank(
         stampedEntityType,
         'stampedEntityType',
       ),
       sourceSystem = requireNotBlank(sourceSystem, 'sourceSystem'),
       sourceKeys = Map.unmodifiable(sourceKeys),
       sourceValues = sourceValues == null
           ? null
           : Map.unmodifiable(sourceValues),
       fileFingerprint = requireNotBlank(fileFingerprint, 'fileFingerprint'),
       toolVersion = requireNotBlank(toolVersion, 'toolVersion'),
       importedAt = importedAt.toUtc() {
    requireNonNegative(revision, 'revision');
    if (dedupeKey != null && stampedEntityType != contestEntityType) {
      throw ArgumentError('only a Contest row carries a dedupe_key');
    }
    if (sourceValues != null && stampedEntityType != contestEntityType) {
      throw ArgumentError('only a Contest row carries source_values');
    }
    if (!entityTypes.contains(stampedEntityType)) {
      throw ArgumentError.value(
        stampedEntityType,
        'stampedEntityType',
        'must be one of ${entityTypes.join(', ')}',
      );
    }
    if (!sourceSystems.contains(sourceSystem)) {
      throw ArgumentError.value(
        sourceSystem,
        'sourceSystem',
        'must be one of ${sourceSystems.join(', ')}',
      );
    }
    if (stampedEntityType == profileEntityType) {
      if (contestId != null) {
        throw ArgumentError('a ParticipantProfile row has no contest_id');
      }
    } else if (contestId == null) {
      throw ArgumentError('a $stampedEntityType row needs a contest_id');
    } else if (stampedEntityType == contestEntityType &&
        stampedEntityId != contestId) {
      throw ArgumentError('a Contest row stamps its own contest');
    }
  }

  factory ImportProvenance.fromJson(Map<String, Object?> json) =>
      _$ImportProvenanceFromJson(json);

  /// The `stamped_entity_type` of a contest row.
  static const contestEntityType = 'Contest';

  /// The `stamped_entity_type` of a participation row.
  static const participationEntityType = 'ContestParticipation';

  /// The `stamped_entity_type` of a profile row, the only one with no
  /// contest.
  static const profileEntityType = 'ParticipantProfile';

  /// The only source system so far.
  static const gliderScore = 'gliderscore';

  /// The entity types a stamp may describe. A new source or phase that
  /// stamps another type adds it here, in the entity doc and in the ADR.
  static const entityTypes = {
    contestEntityType,
    participationEntityType,
    profileEntityType,
  };

  /// The source systems a stamp may name.
  static const sourceSystems = {gliderScore};

  @override
  final Id id;

  /// The importing director: the signed-in account, otherwise the
  /// installation's Local account (re-pointed when that is claimed).
  final Id ownerAccountId;

  /// Set for contest and participation rows, null for profile rows.
  final Id? contestId;

  /// `Contest`, `ContestParticipation` or `ParticipantProfile`.
  final String stampedEntityType;
  final Id stampedEntityId;

  final String sourceSystem;

  /// The source keys of the row: the competition number for a contest, the
  /// competition and pilot number for a participation, the pilot number for
  /// a profile. See `canonicalSourceKeys`.
  final Map<String, Object?> sourceKeys;

  /// Contest rows only: source values that have no field in Soar Score and
  /// are kept for review and later phases (for example the lane count).
  final Map<String, Object?>? sourceValues;

  /// Hash of the source file, the same for every row of one import.
  final String fileFingerprint;

  /// Contest rows only: `<source_system>:<file_fingerprint>:<comp_no>`.
  /// Unique together with [ownerAccountId], so a competition is imported once
  /// per director and file.
  final String? dedupeKey;

  /// One id per import run, shared by every row it wrote.
  final Id importOperationId;

  final String toolVersion;
  final DateTime importedAt;

  @override
  final int revision;

  @override
  String get entityType => 'ImportProvenance';

  @override
  SyncScope get syncScope => SyncScope.director;

  Map<String, Object?> toJson() => _$ImportProvenanceToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    contestId,
    stampedEntityType,
    stampedEntityId,
    sourceSystem,
    sourceKeys,
    sourceValues,
    fileFingerprint,
    dedupeKey,
    importOperationId,
    toolVersion,
    importedAt,
    revision,
  ];
}

/// Builds the canonical form of source keys and the dedupe key.
///
/// Keys are sorted, integers are plain decimals and nothing else is allowed,
/// so two runs that mean the same thing compare equal as text.
abstract final class ProvenanceKeys {
  /// [keys] as canonical JSON text: sorted keys, no whitespace, integers only.
  static String canonicalSourceKeys(Map<String, Object?> keys) {
    final names = keys.keys.toList()..sort();
    final parts = <String>[];
    for (final name in names) {
      final value = keys[name];
      if (value is! int) {
        throw ArgumentError.value(value, name, 'source keys are whole numbers');
      }
      parts.add('"${_escape(name)}":$value');
    }
    return '{${parts.join(',')}}';
  }

  /// The contest dedupe key.
  static String contestDedupeKey({
    required String sourceSystem,
    required String fileFingerprint,
    required int compNo,
  }) => '$sourceSystem:$fileFingerprint:$compNo';

  static String _escape(String name) =>
      name.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
