import 'package:equatable/equatable.dart';

/// How far one checklist item is. Each has its own icon and text label in the
/// card, so the status never rests on colour alone.
enum ChecklistStatus {
  /// Finished.
  done('Done'),

  /// Not started, and nothing is wrong.
  todo('To do'),

  /// Required and absent: something has to be added.
  missing('Missing'),

  /// Present, but needs a look: a matrix that no longer matches the
  /// configuration.
  check('Check'),

  /// Could not be read, which is not the same as not done.
  unknown('Unknown');

  const ChecklistStatus(this.label);

  final String label;
}

/// Where an item sends the director.
enum ChecklistTarget {
  /// The contest's Configuration page.
  configuration,

  /// The Participants page.
  participants,

  /// The contest's Matrix page.
  matrix,

  /// The publication control card on the workspace.
  publicationControl,

  /// The participant-scoring control card on the workspace.
  scoringControl,
}

/// The seven items, in the order the card lists them.
enum ChecklistItemId {
  configuration,
  discipline,
  pilots,
  matrix,
  participantNumbers,
  publication,
  scoringAccess,
}

/// One row of the setup checklist: what it is, how far along, and where it is
/// fixed.
class ChecklistItem extends Equatable {
  const ChecklistItem({
    required this.id,
    required this.status,
    required this.title,
    required this.detail,
    required this.target,
  });

  final ChecklistItemId id;
  final ChecklistStatus status;
  final String title;

  /// One line saying what is done or what is needed.
  final String detail;
  final ChecklistTarget target;

  /// What a screen reader says for the row: the title, the status and the
  /// detail, so the status is spoken and not only shown.
  String get semanticLabel => '$title. ${status.label}. $detail';

  @override
  List<Object?> get props => [id, status, title, detail, target];
}
