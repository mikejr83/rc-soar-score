import 'package:equatable/equatable.dart';

import 'participant_field.dart';
import 'participant_form_values.dart';

/// Which version of a field the director keeps when reviewing a conflict.
enum ReviewChoice { mine, theirs }

/// One field whose stored value changed elsewhere while the director edited.
class FieldDifference extends Equatable {
  const FieldDifference({
    required this.field,
    required this.mine,
    required this.theirs,
    required this.choice,
  });

  final ParticipantField field;
  final String mine;
  final String theirs;
  final ReviewChoice choice;

  FieldDifference choose(ReviewChoice choice) =>
      FieldDifference(field: field, mine: mine, theirs: theirs, choice: choice);

  @override
  List<Object?> get props => [field, mine, theirs, choice];
}

/// The comparison shown after a stale-revision refusal.
///
/// Only fields where the director's text differs from the newest stored
/// text are listed. A field starts on the director's value when they changed
/// it from the version they opened, and on the stored value when they did
/// not, so usually they only confirm.
class ParticipantReview extends Equatable {
  const ParticipantReview(this.differences);

  factory ParticipantReview.build({
    required ParticipantFormValues opened,
    required ParticipantFormValues mine,
    required ParticipantFormValues theirs,
  }) => ParticipantReview([
    for (final field in mine.differences(theirs))
      FieldDifference(
        field: field,
        mine: mine[field].trim(),
        theirs: theirs[field].trim(),
        choice: mine[field].trim() == opened[field].trim()
            ? ReviewChoice.theirs
            : ReviewChoice.mine,
      ),
  ]);

  final List<FieldDifference> differences;

  ParticipantReview choose(ParticipantField field, ReviewChoice choice) =>
      ParticipantReview([
        for (final difference in differences)
          difference.field == field ? difference.choose(choice) : difference,
      ]);

  /// [mine] with every field set to the version the director picked.
  ParticipantFormValues resolve(ParticipantFormValues mine) {
    var resolved = mine;
    for (final difference in differences) {
      resolved = resolved.withField(
        difference.field,
        difference.choice == ReviewChoice.theirs
            ? difference.theirs
            : difference.mine,
      );
    }
    return resolved;
  }

  @override
  List<Object?> get props => [differences];
}
