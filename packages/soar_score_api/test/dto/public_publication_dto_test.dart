import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final publicationId = Id.parse('019c0000-0000-7000-8000-000000000030');
  final publishedAt = DateTime.utc(2026, 10, 17, 14);
  final contest = <String, Object?>{'name': 'Front Range ALES Open'};

  group('PublicPublicationSummaryDto', () {
    test('decodes what the server serves and encodes it back', () {
      final served = PublicPublicationSummary(
        publicationId: publicationId.value,
        publishedAt: publishedAt,
        projectionRevision: 3,
        contest: contest,
        disciplineType: 'F5J',
      ).toJson();

      final dto = PublicPublicationSummaryDto.fromJson(served);

      expect(dto.publicationId, publicationId);
      expect(dto.publishedAt, publishedAt);
      expect(dto.projectionRevision, 3);
      expect(dto.contest, contest);
      expect(dto.disciplineType, 'F5J');
      expect(dto.toJson(), served);
    });
  });

  group('PublicPublicationDto', () {
    test('decodes what the server serves and encodes it back', () {
      final served = PublicPublication(
        publicationId: publicationId.value,
        visibility: 'Unlisted',
        projectionRevision: 3,
        publishedAt: publishedAt,
        contest: contest,
        disciplineType: 'F5J',
        calculationVersion: 'f5j-1',
        resultsHiddenThroughRound: 2,
        participants: [
          {'key': 'p1', 'details': null},
        ],
        teams: [
          {'name': 'Team A'},
        ],
        matrix: {'rounds': <Object?>[]},
        scores: [
          {'round': 1},
        ],
        standingRounds: [
          {'ordinal': 1},
        ],
        calculation: {'version': 'f5j-1'},
      ).toJson();

      final dto = PublicPublicationDto.fromJson(served);

      expect(dto.publicationId, publicationId);
      expect(dto.visibility, 'Unlisted');
      expect(dto.resultsHiddenThroughRound, 2);
      expect(dto.participants, served['participants']);
      expect(dto.teams, served['teams']);
      expect(dto.matrix, served['matrix']);
      expect(dto.scores, served['scores']);
      expect(dto.standings, {
        'rounds': [
          {'ordinal': 1},
        ],
      });
      expect(dto.calculation, {'version': 'f5j-1'});
      expect(dto.toJson(), served);
    });

    test('accepts the nullable members as null', () {
      final dto = PublicPublicationDto.fromJson({
        'publication_id': publicationId.value,
        'visibility': 'Public',
        'projection_revision': 1,
        'published_at': publishedAt.toIso8601String(),
        'contest': contest,
        'discipline_type': 'F5J',
        'calculation_version': 'f5j-1',
        'results_hidden_through_round': null,
        'participants': <Object?>[],
        'teams': <Object?>[],
        'matrix': null,
        'scores': <Object?>[],
        'standings': {'rounds': <Object?>[]},
        'calculation': null,
      });

      expect(dto.resultsHiddenThroughRound, isNull);
      expect(dto.matrix, isNull);
      expect(dto.calculation, isNull);
    });
  });
}
