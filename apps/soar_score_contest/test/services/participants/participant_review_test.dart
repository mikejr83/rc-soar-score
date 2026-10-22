import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/participants/participant_field.dart';
import 'package:soar_score_contest/services/participants/participant_form_values.dart';
import 'package:soar_score_contest/services/participants/participant_kept_values.dart';
import 'package:soar_score_contest/services/participants/participant_review.dart';

ParticipantFormValues _v({String club = '', String city = ''}) =>
    ParticipantFormValues({
      ParticipantField.firstName: 'Dana',
      ParticipantField.club: club,
      ParticipantField.city: city,
    });

void main() {
  final opened = _v(club: 'Tampa', city: 'Tampa');
  final theirs = _v(club: 'Orlando', city: 'Orlando');

  test('lists only fields that differ from the stored version', () {
    final mine = _v(club: 'Mine', city: 'Orlando');
    final review = ParticipantReview.build(
      opened: opened,
      mine: mine,
      theirs: theirs,
    );
    expect(review.differences.map((d) => d.field), [ParticipantField.club]);
  });

  test('a field starts on mine when edited, on theirs when not', () {
    final mine = _v(club: 'Mine', city: 'Tampa');
    final review = ParticipantReview.build(
      opened: opened,
      mine: mine,
      theirs: theirs,
    );
    ReviewChoice? of(ParticipantField f) =>
        review.differences.firstWhere((d) => d.field == f).choice;
    expect(of(ParticipantField.club), ReviewChoice.mine);
    expect(of(ParticipantField.city), ReviewChoice.theirs);
  });

  test('resolve applies each pick to the director\'s values', () {
    final mine = _v(club: 'Mine', city: 'Tampa');
    final review = ParticipantReview.build(
      opened: opened,
      mine: mine,
      theirs: theirs,
    ).choose(ParticipantField.club, ReviewChoice.theirs);
    final resolved = review.resolve(mine);
    expect(resolved[ParticipantField.club], 'Orlando');
    expect(resolved[ParticipantField.city], 'Orlando');
    expect(resolved[ParticipantField.firstName], 'Dana');
  });

  test('kept values carry club and location only', () {
    const saved = ParticipantFormValues({
      ParticipantField.firstName: 'Sam',
      ParticipantField.email: 'sam@example.com',
      ParticipantField.club: 'Tampa',
      ParticipantField.country: 'United States',
    });
    final kept = keptValuesOf(saved);
    expect(kept[ParticipantField.club], 'Tampa');
    expect(kept[ParticipantField.country], 'United States');
    expect(kept[ParticipantField.firstName], isEmpty);
    expect(kept[ParticipantField.email], isEmpty);
    expect(hasKeptValues(kept), isTrue);
    expect(hasKeptValues(const ParticipantFormValues()), isFalse);
  });
}
