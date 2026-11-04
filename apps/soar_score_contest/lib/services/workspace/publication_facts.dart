import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What the workspace knows about the contest's publication.
class PublicationFacts extends Equatable {
  const PublicationFacts({
    required this.isPublished,
    this.visibility,
    this.publishedAt,
    this.projection,
    this.pendingDelist,
    this.isKnown = true,
    this.supported = true,
  });

  /// The contest was never published (the server answered 404).
  static const notPublished = PublicationFacts(isPublished: false);

  /// The read failed or is not available here; not the same as unpublished.
  static const unknown = PublicationFacts(isPublished: false, isKnown: false);

  /// Publishing is not a capability of this server (it answered 409
  /// `publishing_not_available`); a stable state, not a failed read.
  static const unsupported = PublicationFacts(
    isPublished: false,
    supported: false,
  );

  /// Reads the director's view of a publication, defensively: a missing or
  /// unexpected field gives [unknown], never a thrown error.
  factory PublicationFacts.fromJson(Map<String, Object?> json) {
    final visibility = switch (json['visibility']) {
      'Unlisted' => PublicationVisibility.unlisted,
      'Public' => PublicationVisibility.public,
      'Delisted' => PublicationVisibility.delisted,
      _ => null,
    };
    if (visibility == null) {
      return unknown;
    }
    final at = json['published_at'];
    return PublicationFacts(
      isPublished: true,
      visibility: visibility,
      publishedAt: at is String ? DateTime.tryParse(at)?.toUtc() : null,
      projection: PublicationProjectionFacts.tryParse(
        json['current_projection'],
      ),
    );
  }

  final bool isPublished;
  final PublicationVisibility? visibility;
  final DateTime? publishedAt;

  /// The latest published copy of the results, when the server sent one.
  final PublicationProjectionFacts? projection;

  /// The delisting request waiting for a system administrator, or null when
  /// there is none (or it could not be read).
  final DelistRequest? pendingDelist;

  /// A delisting request is waiting for a decision.
  bool get delistPending => pendingDelist != null;

  /// These facts with [request] as the pending delisting request.
  PublicationFacts withPendingDelist(DelistRequest? request) =>
      PublicationFacts(
        isPublished: isPublished,
        visibility: visibility,
        publishedAt: publishedAt,
        projection: projection,
        pendingDelist: request,
        isKnown: isKnown,
        supported: supported,
      );

  /// False for [unknown].
  final bool isKnown;

  /// False when the server does not publish contests at all ([unsupported]);
  /// then the state is stable and the rest of the workspace must not treat it
  /// as a failed read.
  final bool supported;

  @override
  List<Object?> get props => [
    isPublished,
    visibility,
    publishedAt,
    projection,
    pendingDelist,
    isKnown,
    supported,
  ];
}

/// A summary of the latest projection (published copy) of a contest.
class PublicationProjectionFacts extends Equatable {
  const PublicationProjectionFacts({
    required this.projectionRevision,
    required this.contestRevision,
    this.publishedAt,
  });

  /// Reads the server's `current_projection`, or null when it is missing or
  /// not the expected shape.
  static PublicationProjectionFacts? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final revision = json['projection_revision'];
    final contestRevision = json['contest_revision'];
    final at = json['published_at'];
    if (revision is! int || contestRevision is! int) {
      return null;
    }
    return PublicationProjectionFacts(
      projectionRevision: revision,
      contestRevision: contestRevision,
      publishedAt: at is String ? DateTime.tryParse(at)?.toUtc() : null,
    );
  }

  final int projectionRevision;

  /// The contest revision this copy was made from.
  final int contestRevision;
  final DateTime? publishedAt;

  @override
  List<Object?> get props => [projectionRevision, contestRevision, publishedAt];
}
