import 'package:soar_score_core/soar_score_core.dart' as core;

/// A repository with only the contest contract; the others are not used by
/// the handlers under test.
class StubRepository implements core.Repository {
  StubRepository(this._contestRepository);

  @override
  core.ContestRepository get contestRepository => _contestRepository;

  final core.ContestRepository _contestRepository;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
