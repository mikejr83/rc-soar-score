import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'published_contest.dart';

/// Fetches one published contest; `ApiClient.publicPublication` in the app,
/// fake data in tests.
typedef PublicationLoader = Future<PublicPublicationDto> Function(Id id);

/// What the contest page got when it asked for a contest.
sealed class ContestLoadResult {
  const ContestLoadResult();

  /// Loads [contestId] with [loader] and sorts the outcome.
  static Future<ContestLoadResult> load(
    PublicationLoader loader,
    String contestId,
  ) async {
    final Id id;
    try {
      id = Id.parse(contestId);
    } on ArgumentError {
      // A malformed id is the spec's "bad URL" case.
      return const ContestNotFound();
    }
    try {
      return ContestLoaded(PublishedContest.fromDto(await loader(id)));
    } on ApiHttpError catch (e) {
      // TODO(#463): the server answers 404 for a pending or private contest
      // too; once it returns a distinct status, map it to ContestNotVisible.
      if (e.statusCode == 404) return const ContestNotFound();
      if (e.statusCode == 403 && e.error?.code == 'contest_not_visible') {
        return const ContestNotVisible();
      }
      return ContestLoadFailed(e.error?.message ?? e.message);
    } on ApiException catch (e) {
      return ContestLoadFailed(e.message);
    }
  }
}

class ContestLoaded extends ContestLoadResult {
  const ContestLoaded(this.results);

  final PublishedContest results;
}

/// Unknown or delisted (HTTP 404).
class ContestNotFound extends ContestLoadResult {
  const ContestNotFound();
}

/// Exists but is pending or private; not signalled by the server yet (#463).
class ContestNotVisible extends ContestLoadResult {
  const ContestNotVisible();
}

class ContestLoadFailed extends ContestLoadResult {
  const ContestLoadFailed(this.message);

  final String message;
}
