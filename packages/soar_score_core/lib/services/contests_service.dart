import 'package:soar_score_core/models/contest/contest.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('ContestsService');

class ContestsService {
  ContestsService(this.repository);

  final Repository repository;

  Future<List<Contest>> getContests() async {
    _logger.info('Fetching contests from the repository');
    return repository.contestRepository.getAll();
  }
}
