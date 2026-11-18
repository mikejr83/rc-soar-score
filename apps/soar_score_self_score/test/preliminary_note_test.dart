import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/officialization_policy.dart';
import 'package:soar_score_self_score/widgets/preliminary_note.dart';

Future<String> _noteFor(
  WidgetTester tester,
  OfficializationPolicy? policy, {
  bool review = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: PreliminaryNote(policy: policy, showReviewHold: review),
      ),
    ),
  );
  return tester
      .widget<Text>(find.byKey(const ValueKey('preliminary-note')))
      .data!;
}

void main() {
  testWidgets('each policy names when the score becomes official', (
    tester,
  ) async {
    expect(
      await _noteFor(tester, OfficializationPolicy.endOfRound),
      contains('all required scores for its round'),
    );
    expect(
      await _noteFor(tester, OfficializationPolicy.endOfGroup),
      contains('all required scores for its group'),
    );
    expect(
      await _noteFor(tester, OfficializationPolicy.manual),
      contains('when the director makes it official'),
    );
  });

  testWidgets('an unknown policy gets the general wording', (tester) async {
    expect(
      await _noteFor(tester, null),
      contains('until the contest makes them official'),
    );
  });

  testWidgets('an open review adds that the score is held', (tester) async {
    expect(
      await _noteFor(tester, OfficializationPolicy.manual),
      isNot(contains('under review')),
    );
    expect(
      await _noteFor(tester, OfficializationPolicy.manual, review: true),
      contains('A score under review is held'),
    );
  });

  test('the wire values map to policies', () {
    expect(
      OfficializationPolicy.fromWire('EndOfGroup'),
      OfficializationPolicy.endOfGroup,
    );
    expect(OfficializationPolicy.fromWire('Other'), isNull);
    expect(OfficializationPolicy.fromWire(null), isNull);
  });
}
