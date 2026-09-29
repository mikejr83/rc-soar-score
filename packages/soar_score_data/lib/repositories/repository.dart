import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

class Repository implements core.Repository {
  Repository(this._contestRepository);

  @override
  core.ContestRepository get contestRepository => _contestRepository;

  final core.ContestRepository _contestRepository;
}

Repository createRepository(SoarScoreDatabase database) {
  return Repository(ContestRepository(database));
}
