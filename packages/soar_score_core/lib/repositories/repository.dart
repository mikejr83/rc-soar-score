import 'package:soar_score_core/repositories/contest_repository.dart';

class Repository {
  Repository(this._contestRepository);

  ContestRepository get contestRepository => _contestRepository;

  final ContestRepository _contestRepository;
}
