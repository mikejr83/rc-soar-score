import 'package:equatable/equatable.dart';

import '../../models/publication/publication_participant.dart';
import '../../models/publication/publication_projection.dart';

/// What the projection builder produces for one publish: the new projection
/// and the participant rows it needs.
///
/// Nothing is stored. The publish route writes [projection] and
/// [participants] together.
class PublicationBuild extends Equatable {
  PublicationBuild({
    required this.projection,
    Iterable<PublicationParticipant> participants = const [],
  }) : participants = List.unmodifiable(participants);

  final PublicationProjection projection;

  /// The participants to save: new ones, and existing ones whose details
  /// changed. Redacted rows are never included.
  final List<PublicationParticipant> participants;

  @override
  List<Object?> get props => [projection, participants];
}
