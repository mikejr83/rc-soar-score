import 'package:equatable/equatable.dart';

import '../../models/publication/publication_identity.dart';
import '../../models/publication/publication_projection.dart';

/// A publication as its director sees it: the identity and a summary of the
/// current projection, without the projection's content.
class PublicationView extends Equatable {
  const PublicationView({required this.identity, this.current});

  final PublicationIdentity identity;

  /// The latest projection, or null when none exists.
  final PublicationProjection? current;

  Map<String, Object?> toJson() => {
    'publication_id': identity.id.value,
    'contest_id': identity.contestId?.value,
    'visibility': identity.toJson()['visibility'],
    'claim_status': identity.toJson()['claim_status'],
    'published_at': identity.publishedAt?.toIso8601String(),
    'results_hidden_through_round': identity.resultsHiddenThroughRound,
    'current_projection': current == null
        ? null
        : {
            'id': current!.id.value,
            'projection_revision': current!.projectionRevision,
            'contest_revision': current!.contestRevision,
            'config_revision': current!.configRevision,
            'matrix_revision': current!.matrixRevision,
            'calculation_version': current!.calculationVersion,
            'published_at': current!.publishedAt.toIso8601String(),
          },
  };

  @override
  List<Object?> get props => [identity, current];
}

/// One projection in a publication's history, with who published it.
class PublicationHistoryEntry extends Equatable {
  const PublicationHistoryEntry({
    required this.projection,
    required this.bySystem,
  });

  final PublicationProjection projection;

  /// True for an automatic publish by the director's update mode, false for
  /// a publish the director asked for. Taken from the publish's audit event,
  /// because an automatic publish still records the owner as `publishedBy`.
  final bool bySystem;

  @override
  List<Object?> get props => [projection, bySystem];
}

/// The result of a publish request.
class PublishResult extends Equatable {
  const PublishResult({required this.view, required this.created});

  final PublicationView view;

  /// False when the request repeated an earlier one and nothing was added.
  final bool created;

  @override
  List<Object?> get props => [view, created];
}
