import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/team_marker.dart';
import 'package:soar_score_core/soar_score_core.dart';

Team _team(int n, String name) => Team(
  id: Id.parse(
    '019c0000-0000-7000-8000-0000000001${n.toString().padLeft(2, '0')}',
  ),
  contestId: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: name,
);

void main() {
  test('codes come from the initials and stay unique', () {
    final markers = TeamMarkers.of([
      _team(1, 'Flying Gators'),
      _team(2, 'Fast Grinders'),
      _team(3, 'Lake Wings'),
    ]);
    final codes = [for (final (_, marker) in markers.ordered) marker.code];
    expect(codes.toSet().length, 3);
    expect(
      markers.of(Id.parse('019c0000-0000-7000-8000-000000000103'))?.code,
      'LW',
    );
    expect(codes, contains('FG'));
  });

  test('markers follow team-name order', () {
    final markers = TeamMarkers.of([_team(1, 'Zed'), _team(2, 'Alpha')]);
    expect(markers.ordered.first.$2.name, 'Alpha');
    expect(markers.ordered.first.$2.paletteIndex, 0);
  });

  test('teams 13 and up are outlined', () {
    final markers = TeamMarkers.of([
      for (var i = 0; i < 15; i++)
        _team(i + 1, 'Team ${String.fromCharCode(65 + i)}'),
    ]);
    final outlined = [
      for (final (_, marker) in markers.ordered) marker.outlined,
    ];
    expect(outlined.where((o) => o).length, 3);
    expect(outlined.take(12).any((o) => o), isFalse);
  });

  test('a pilot without a team has no marker', () {
    expect(TeamMarkers.of([_team(1, 'A B')]).of(null), isNull);
  });
}
