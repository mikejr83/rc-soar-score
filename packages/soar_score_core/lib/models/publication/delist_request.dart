import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/delist_state.dart';
import '../../enums/delist_trigger.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'delist_request.g.dart';

/// A request to remove a published result set from public view.
///
/// Backend only. A system administrator approves or denies it. See
/// `plan/data-model/entities/delist_request.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DelistRequest extends Equatable implements BackendOnly {
  DelistRequest({
    required this.id,
    required this.publicationId,
    required this.requestedBy,
    required this.trigger,
    this.reason,
    required DateTime requestedAt,
    this.state = DelistState.pending,
    this.decidedBy,
    DateTime? decidedAt,
    String? decisionNote,
  }) : requestedAt = requestedAt.toUtc(),
       decidedAt = decidedAt?.toUtc(),
       decisionNote = decisionNote?.trim() {
    final decided =
        state == DelistState.approved || state == DelistState.denied;
    final decisionFields = [decidedBy, decidedAt, this.decisionNote];
    if (decided && decisionFields.contains(null)) {
      throw ArgumentError('a decision records who decided, when, and why');
    }
    if (!decided && decisionFields.any((field) => field != null)) {
      throw ArgumentError('only an approved or denied request has a decision');
    }
    if (decided && this.decisionNote!.isEmpty) {
      throw ArgumentError.value(
        decisionNote,
        'decisionNote',
        'must not be blank',
      );
    }
  }

  factory DelistRequest.fromJson(Map<String, Object?> json) =>
      _$DelistRequestFromJson(json);

  final Id id;
  final Id publicationId;
  final Id requestedBy;
  final DelistTrigger trigger;
  final String? reason;
  final DateTime requestedAt;
  final DelistState state;

  /// The system administrator who decided.
  final Id? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;

  bool get isPending => state == DelistState.pending;

  Map<String, Object?> toJson() => _$DelistRequestToJson(this);

  @override
  List<Object?> get props => [
    id,
    publicationId,
    requestedBy,
    trigger,
    reason,
    requestedAt,
    state,
    decidedBy,
    decidedAt,
    decisionNote,
  ];
}
