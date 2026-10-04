import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'team.g.dart';

/// A contest-scoped team: a name and, through memberships, its members.
///
/// See `plan/data-model/entities/team.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Team extends Equatable implements Synchronizable {
  Team({
    required this.id,
    required this.contestId,
    required String name,
    this.revision = 0,
  }) : name = requireNotBlank(name, 'name') {
    requireNonNegative(revision, 'revision');
  }

  factory Team.fromJson(Map<String, Object?> json) => _$TeamFromJson(json);

  @override
  final Id id;
  final Id contestId;

  /// Unique within the contest.
  final String name;

  @override
  final int revision;

  @override
  String get entityType => 'Team';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$TeamToJson(this);

  @override
  List<Object?> get props => [id, contestId, name, revision];
}
