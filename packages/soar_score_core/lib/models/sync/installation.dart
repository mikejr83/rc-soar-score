import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/platform.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'installation.g.dart';

/// A director's app instance: the web app or the desktop app on one device.
///
/// Backend only; never deleted, because mutations and audit events refer to
/// it. See `plan/data-model/entities/installation.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Installation extends Equatable implements BackendOnly {
  Installation({
    required this.id,
    required this.ownerAccountId,
    required String label,
    required this.platform,
    required this.createdAt,
    this.lastSeenAt,
    this.lastSyncAt,
    this.systemDataSeq = 0,
    this.revokedAt,
  }) : label = requireNotBlank(label, 'label') {
    requireNonNegative(systemDataSeq, 'systemDataSeq');
  }

  factory Installation.fromJson(Map<String, Object?> json) =>
      _$InstallationFromJson(json);

  final Id id;

  /// The director who owns the installation.
  final Id ownerAccountId;

  /// A name the director recognizes, for example "Field laptop".
  final String label;

  final Platform platform;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final DateTime? lastSyncAt;

  /// The last system-data sequence it has applied; only ever increases.
  final int systemDataSeq;

  /// When the director revoked it; a revoked installation cannot synchronize.
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  Map<String, Object?> toJson() => _$InstallationToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    label,
    platform,
    createdAt,
    lastSeenAt,
    lastSyncAt,
    systemDataSeq,
    revokedAt,
  ];
}
