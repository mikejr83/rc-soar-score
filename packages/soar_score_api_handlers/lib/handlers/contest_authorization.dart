import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Requires [request] to act as the owner of [contestId].
///
/// Throws [EntityNotFoundError] for an unknown id (404) and
/// [ForbiddenError] (`not_director`, 403) for any other account.
Future<void> requireContestDirector(
  Request request,
  Repository repository,
  Id contestId,
) async {
  final principal = requirePrincipal(request);
  final contest = await repository.contestRepository.findById(contestId);
  if (contest == null) {
    throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
  }
  if (contest.ownerAccountId != principal.accountId) {
    throw ForbiddenError('not_director', 'only the director of the contest may');
  }
}
