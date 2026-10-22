import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What the workspace knows about the contest's publication.
class PublicationFacts extends Equatable {
  const PublicationFacts({
    required this.isPublished,
    this.visibility,
    this.publishedAt,
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
    );
  }

  final bool isPublished;
  final PublicationVisibility? visibility;
  final DateTime? publishedAt;

  /// False for [unknown].
  final bool isKnown;

  /// False when the server does not publish contests at all ([unsupported]);
  /// then the state is stable and the rest of the workspace must not treat it
  /// as a failed read.
  final bool supported;

  @override
  List<Object?> get props =>
      [isPublished, visibility, publishedAt, isKnown, supported];
}
