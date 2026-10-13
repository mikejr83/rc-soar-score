import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/contest/fixtures.dart';

class _FakeContestRepository implements ContestRepository {
  _FakeContestRepository(this.contests);

  final List<Contest> contests;

  @override
  Future<List<Contest>> getAll() async => contests;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class _FakeRepository implements Repository {
  _FakeRepository(this.contestRepository);

  @override
  final ContestRepository contestRepository;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  group('ContestsService.getContests', () {
    test('returns an empty list when nothing is stored', () async {
      final service = ContestsService(
        _FakeRepository(_FakeContestRepository([])),
      );

      expect(await service.getContests(), isEmpty);
    });

    test('returns the contests the repository holds', () async {
      final contests = [makeContest(), makeContest(name: 'Second Open')];
      final service = ContestsService(
        _FakeRepository(_FakeContestRepository(contests)),
      );

      expect(await service.getContests(), contests);
    });
  });
}
