import 'package:equatable/equatable.dart';

import '../workspace_facts.dart';
import 'checklist_item.dart';
import 'optional_checklist_rows.dart';
import 'required_checklist_rows.dart';

/// The setup checklist for one contest: four required rows and up to three
/// optional ones, worked out from [WorkspaceFacts].
///
/// Whether the card shows at all is the layout plan's decision (Created,
/// Configuring and Ready). The rules behind the rows are the existing ones:
/// draw readiness, configuration drift and the configuration problem.
class SetupChecklist extends Equatable {
  const SetupChecklist({required this.required, required this.optional});

  /// [formatSavedAt] writes the time the configuration was saved (the screens
  /// pass `DirectorTime.of(context)`).
  factory SetupChecklist.resolve(
    WorkspaceFacts facts, {
    required String Function(DateTime savedAt) formatSavedAt,
  }) {
    final optionalNumbers = OptionalChecklistRows.participantNumbers(facts);
    return SetupChecklist(
      required: [
        RequiredChecklistRows.configuration(facts, formatSavedAt),
        RequiredChecklistRows.discipline(facts),
        RequiredChecklistRows.pilots(facts),
        RequiredChecklistRows.matrix(facts),
      ],
      optional: [
        ?optionalNumbers,
        OptionalChecklistRows.publication(facts),
        OptionalChecklistRows.scoringAccess(facts),
      ],
    );
  }

  final List<ChecklistItem> required;
  final List<ChecklistItem> optional;

  int get doneRequired =>
      required.where((item) => item.status == ChecklistStatus.done).length;

  /// "3 of 4 required items done".
  String get summary =>
      '$doneRequired of ${required.length} required items '
      'done';

  /// Every required item is done.
  bool get requiredComplete => doneRequired == required.length;

  @override
  List<Object?> get props => [required, optional];
}
