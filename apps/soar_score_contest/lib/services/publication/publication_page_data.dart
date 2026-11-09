import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/publication_facts.dart';
import '../workspace/publication_facts_loader.dart';

final _logger = Logger('PublicationPageData');

/// The most copies the server returns in one history request.
const _historyPage = 100;

/// What the Publication page shows about one contest.
class PublicationPageData extends Equatable {
  const PublicationPageData({
    required this.contest,
    required this.publication,
    required this.policy,
    this.policyReadFailed = false,
    this.history = const [],
    this.historyReadFailed = false,
  });

  final Contest contest;
  final PublicationFacts publication;

  /// The public update policy from the contest's options, or null when none
  /// are saved.
  final PublicUpdateMode? policy;

  /// True when the configuration could not be read, so [policy] is unknown
  /// rather than unset.
  final bool policyReadFailed;

  /// Every published copy, newest first (empty when unpublished or when
  /// [historyReadFailed]).
  final List<PublicationHistoryEntryDto> history;

  /// True when the history could not be read; the page says so and still
  /// works.
  final bool historyReadFailed;

  /// Loads the contest, its saved options and its publication. A failed
  /// publication read is [PublicationFacts.unknown], not an error.
  ///
  /// The contest and its options come from [client], the app's own data. The
  /// publication and its history come from [publicationClient], the hosted
  /// server on native; it defaults to [client].
  static Future<PublicationPageData> load(
    ApiClient client,
    Id id, {
    ApiClient? publicationClient,
  }) async {
    final remote = publicationClient ?? client;
    final contest = await client.contest(id);
    final (policyRead, publication) = await (
      _policy(client, id),
      PublicationFactsLoader.load(remote, id),
    ).wait;
    final (history, historyFailed) = publication.isPublished
        ? await _history(remote, id)
        : (const <PublicationHistoryEntryDto>[], false);
    return PublicationPageData(
      contest: contest,
      publication: publication,
      policy: policyRead.$1,
      policyReadFailed: policyRead.$2,
      history: history,
      historyReadFailed: historyFailed,
    );
  }

  /// The newest copies and whether reading them failed; a failure is logged
  /// and flagged, and does not fail the page.
  static Future<(List<PublicationHistoryEntryDto>, bool)> _history(
    ApiClient client,
    Id id,
  ) async {
    try {
      // The server pages at most 100 at a time; read until a short page so
      // the list is every copy, not just the newest 100.
      final all = <PublicationHistoryEntryDto>[];
      while (true) {
        final page = await client.publicationProjections(
          id,
          limit: _historyPage,
          offset: all.length,
        );
        all.addAll(page);
        if (page.length < _historyPage) {
          return (all, false);
        }
      }
    } on Object catch (error, stack) {
      _logger.warning('Could not read the publication history', error, stack);
      return (const <PublicationHistoryEntryDto>[], true);
    }
  }

  /// The saved public update policy and whether reading it failed. Only the
  /// configuration is read; a failure is logged and flagged so the page can
  /// say so, but it does not fail the page.
  static Future<(PublicUpdateMode?, bool)> _policy(
    ApiClient client,
    Id id,
  ) async {
    try {
      final configuration = await MatrixPageData.latestConfiguration(
        client,
        id,
      );
      return (configuration?.config.coreOptions.publicUpdateMode, false);
    } on Object catch (error, stack) {
      _logger.warning('Could not read the public update policy', error, stack);
      return (null, true);
    }
  }

  @override
  List<Object?> get props => [
    contest,
    publication,
    policy,
    policyReadFailed,
    history.map((e) => e.id).toList(),
    historyReadFailed,
  ];
}
