import 'package:soar_score_core/soar_score_core.dart' as core;

class StubRepository implements core.Repository {
  StubRepository(this._contestRepository);

  @override
  core.ContestRepository get contestRepository => _contestRepository;

  final core.ContestRepository _contestRepository;
}
