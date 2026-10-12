import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Which of the workspace's page states applies (design section 7,
/// "Failure and page states").
sealed class WorkspacePageState extends Equatable {
  const WorkspacePageState();

  /// The state for the result of loading the contest.
  ///
  /// [contest] wins over [error]: a failed reload keeps the page that is
  /// already showing. An id that does not parse, or a 404, is not found;
  /// every other failure, including having no API client, is a load failure.
  /// Neither loaded nor failed yet is loading.
  factory WorkspacePageState.of({
    required bool idValid,
    Contest? contest,
    Object? error,
    bool stale = false,
  }) {
    if (!idValid) {
      return const WorkspaceNotFound();
    }
    if (contest != null) {
      return WorkspaceReady(stale: stale);
    }
    if (error is ApiHttpError && error.statusCode == 404) {
      return const WorkspaceNotFound();
    }
    if (error != null) {
      return WorkspaceLoadFailed(error);
    }
    return const WorkspaceLoading();
  }

  @override
  List<Object?> get props => const [];
}

/// The contest is being loaded.
class WorkspaceLoading extends WorkspacePageState {
  const WorkspaceLoading();
}

/// The route's id is not a contest, here or on the server.
class WorkspaceNotFound extends WorkspacePageState {
  const WorkspaceNotFound();
}

/// The contest could not be loaded and nothing shows in its place.
class WorkspaceLoadFailed extends WorkspacePageState {
  const WorkspaceLoadFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// The contest is loaded; the page shows, with banners for what is off.
class WorkspaceReady extends WorkspacePageState {
  const WorkspaceReady({this.stale = false, this.localCopyAt});

  /// A change was rejected as out of date (409); the page content is
  /// unchanged and the banner offers a refresh.
  final bool stale;

  /// When the local copy shown in place of an unreachable server was taken.
  ///
  /// Never set yet: the page has no local copy to read until the local store
  /// lands (#319), and does not pretend to have one.
  final DateTime? localCopyAt;

  bool get unavailable => localCopyAt != null;

  @override
  List<Object?> get props => [stale, localCopyAt];
}
