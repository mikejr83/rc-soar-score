import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_creator.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  test('the wizard saves the back-to-back choice in the core options', () {
    final off = ContestDraft(draw: const DrawSettings(allowBackToBack: false));
    final on = ContestDraft();

    expect(ContestCreator.coreOptionsOf(off)['allow_back_to_back'], isFalse);
    expect(ContestCreator.coreOptionsOf(on)['allow_back_to_back'], isTrue);
    expect(
      CoreOptions.fromMap(ContestCreator.coreOptionsOf(off)).allowBackToBack,
      isFalse,
    );
  });

  test('the wizard saves when scores become official in the core options', () {
    expect(
      ContestCreator.coreOptionsOf(ContestDraft())['scores_become_official'],
      'EndOfRound',
    );
    final manual = ContestDraft(
      scoring: ScoringSettings.defaultsFor(null)
          .copyWith(scoresBecomeOfficial: OfficializationMode.manual),
    );
    final options = ContestCreator.coreOptionsOf(manual);
    expect(options['scores_become_official'], 'Manual');
    expect(
      CoreOptions.fromMap(options).scoresBecomeOfficial,
      OfficializationMode.manual,
    );
  });
}
