import 'package:json_annotation/json_annotation.dart';

/// When submitted scores become official (`scores_become_official` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`. It is
/// independent of [PublicUpdateMode]: accepting a score never publishes it.
@JsonEnum(valueField: 'json')
enum OfficializationMode {
  /// The contest accepts a round's submitted scores once every required
  /// score of the round has been submitted. The default of a new contest.
  endOfRound('EndOfRound'),

  /// The same, for each flight group.
  endOfGroup('EndOfGroup'),

  /// Only the director makes scores official. A contest with no stored
  /// setting reads as this, so older contests do not change.
  manual('Manual');

  const OfficializationMode(this.json);

  final String json;
}
