import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/contest_list.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest(String id, String name, DateTime start) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-00000000000$id'),
  name: name,
  startDateTime: start,
  endDateTime: start.add(const Duration(days: 1)),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 1),
  updatedAt: DateTime.utc(2026, 1),
);

void main() {
  test('newestFirst puts the latest start on top, ties by name then id', () {
    final spring = _contest('1', 'Spring', DateTime.utc(2026, 3, 14));
    final autumn = _contest('2', 'Autumn', DateTime.utc(2026, 10, 10));
    final beta = _contest('3', 'beta', DateTime.utc(2026, 6, 14));
    final alpha = _contest('4', 'Alpha', DateTime.utc(2026, 6, 14));
    final twin = _contest('5', 'Alpha', DateTime.utc(2026, 6, 14));

    final sorted = ContestList.newestFirst([spring, twin, beta, autumn, alpha]);

    expect(sorted, [autumn, alpha, twin, beta, spring]);
  });
}
