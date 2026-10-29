import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'matrix_revision_summary.g.dart';

/// One entry of `GET /api/v1/contests/{id}/matrix/revisions`: the facts of a
/// single matrix revision, newest first.
///
/// Superseded revisions stay listed so the draw history can be shown; the
/// read-only matrix of one revision is a separate read.
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
@IdConverter()
@UtcTimestampConverter()
class MatrixRevisionSummary {
  const MatrixRevisionSummary({
    required this.id,
    required this.revisionNumber,
    required this.createdAt,
    this.reason,
    required this.createdBy,
    required this.firstRound,
    required this.lastRound,
    required this.algorithmVersion,
    required this.randomSeed,
    this.fairnessScore,
  });

  factory MatrixRevisionSummary.fromJson(Map<String, dynamic> json) =>
      _$MatrixRevisionSummaryFromJson(json);

  factory MatrixRevisionSummary.of(MatrixRevision revision) =>
      MatrixRevisionSummary(
        id: revision.id,
        revisionNumber: revision.revisionNumber,
        createdAt: revision.createdAt,
        reason: revision.reason,
        createdBy: revision.createdBy,
        firstRound: revision.firstRound,
        lastRound: revision.lastRound,
        algorithmVersion: revision.algorithmVersion,
        randomSeed: revision.randomSeed,
        fairnessScore: revision.fairnessSummary?['fairness_score'] as num?,
      );

  final Id id;
  final int revisionNumber;
  final DateTime createdAt;
  final String? reason;
  final Id createdBy;
  final int firstRound;
  final int lastRound;
  final String algorithmVersion;
  final int randomSeed;

  /// The overall fairness score of the draw's fairness report.
  final num? fairnessScore;

  Map<String, dynamic> toJson() => _$MatrixRevisionSummaryToJson(this);
}
