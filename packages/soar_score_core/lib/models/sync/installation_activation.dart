import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/activation_kind.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'installation_activation.g.dart';

/// Which installation holds administrative authority over a contest, and for
/// how long.
///
/// Backend only. `endedAt` is the only value that changes after creation, so
/// [close] returns a copy. See
/// `plan/data-model/entities/installation_activation.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class InstallationActivation extends Equatable implements BackendOnly {
  InstallationActivation({
    required this.id,
    required this.contestId,
    required this.installationId,
    required this.activatedBy,
    required this.kind,
    required this.activatedAt,
    this.endedAt,
    this.uploadOpen = false,
  }) {
    if (endedAt != null && endedAt!.isBefore(activatedAt)) {
      throw ArgumentError.value(
        endedAt,
        'endedAt',
        'must not precede activatedAt',
      );
    }
  }

  factory InstallationActivation.fromJson(Map<String, Object?> json) =>
      _$InstallationActivationFromJson(json);

  final Id id;
  final Id contestId;

  /// The installation that holds authority.
  final Id installationId;

  /// The director's account that activated it.
  final Id activatedBy;

  final ActivationKind kind;

  /// When authority was granted (server time).
  final DateTime activatedAt;

  /// When authority ended; null while this is the open row.
  final DateTime? endedAt;

  /// True while the contest's first upload is still being sent in several
  /// exchanges: the installation may then say `first_upload` and keep the
  /// contest's history exempt from the lock and completed rules. Closed
  /// explicitly when the upload finishes.
  final bool uploadOpen;

  bool get isOpen => endedAt == null;

  /// A copy with authority ended at [at].
  InstallationActivation close(DateTime at) {
    if (!isOpen) throw StateError('activation $id has already ended');
    return InstallationActivation(
      id: id,
      contestId: contestId,
      installationId: installationId,
      activatedBy: activatedBy,
      kind: kind,
      activatedAt: activatedAt,
      endedAt: at,
    );
  }

  /// A copy with [uploadOpen] set.
  InstallationActivation withUploadOpen(bool open) => InstallationActivation(
    id: id,
    contestId: contestId,
    installationId: installationId,
    activatedBy: activatedBy,
    kind: kind,
    activatedAt: activatedAt,
    endedAt: endedAt,
    uploadOpen: open,
  );

  Map<String, Object?> toJson() => _$InstallationActivationToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    installationId,
    activatedBy,
    kind,
    activatedAt,
    endedAt,
    uploadOpen,
  ];
}
