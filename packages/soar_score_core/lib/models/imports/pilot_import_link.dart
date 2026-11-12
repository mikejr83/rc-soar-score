import 'package:equatable/equatable.dart';

import '../id.dart';
import '../shared/shared.dart';

/// An explicitly confirmed association between a source pilot and profile.
class PilotImportLink extends Equatable implements Synchronizable {
  PilotImportLink({
    required this.id,
    required this.ownerAccountId,
    required this.sourcePilotNo,
    required this.participantProfileId,
    required Map<String, Object?> sourceValues,
    required this.createdAt,
    required this.updatedAt,
    this.sourceSystem = 'gliderscore6',
    this.revision = 0,
  }) : sourceValues = Map.unmodifiable(sourceValues);
  @override
  final Id id;
  final Id ownerAccountId;
  final String sourceSystem;
  final int sourcePilotNo;
  final Id participantProfileId;
  final Map<String, Object?> sourceValues;
  final DateTime createdAt;
  final DateTime updatedAt;
  @override
  final int revision;
  @override
  String get entityType => 'PilotImportLink';
  @override
  SyncScope get syncScope => SyncScope.director;
  factory PilotImportLink.fromJson(Map<String, Object?> json) =>
      PilotImportLink(
        id: Id.parse(json['id'] as String),
        ownerAccountId: Id.parse(json['owner_account_id'] as String),
        sourceSystem: json['source_system'] as String,
        sourcePilotNo: json['source_pilot_no'] as int,
        participantProfileId: Id.parse(
          json['participant_profile_id'] as String,
        ),
        sourceValues: Map<String, Object?>.from(json['source_values'] as Map),
        createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
        revision: json['revision'] as int? ?? 0,
      );
  Map<String, Object?> toJson() => {
    'id': id.value,
    'owner_account_id': ownerAccountId.value,
    'source_system': sourceSystem,
    'source_pilot_no': sourcePilotNo,
    'participant_profile_id': participantProfileId.value,
    'source_values': sourceValues,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'revision': revision,
  };
  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    sourceSystem,
    sourcePilotNo,
    participantProfileId,
    sourceValues,
    createdAt,
    updatedAt,
    revision,
  ];
}
