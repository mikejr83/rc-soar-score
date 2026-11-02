import 'package:equatable/equatable.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/publication_facts.dart';
import '../workspace/publication_facts_loader.dart';

/// What the Publication page shows about one contest.
class PublicationPageData extends Equatable {
  const PublicationPageData({
    required this.contest,
    required this.publication,
    required this.policy,
  });

  final Contest contest;
  final PublicationFacts publication;

  /// The public update policy from the contest's options, or null when none
  /// are saved.
  final PublicUpdateMode? policy;

  /// Loads the contest, its saved options and its publication. A failed
  /// publication read is [PublicationFacts.unknown], not an error.
  static Future<PublicationPageData> load(ApiClient client, Id id) async {
    final contest = await client.contest(id);
    final (policy, publication) = await (
      _policy(client, id),
      PublicationFactsLoader.load(client, id),
    ).wait;
    return PublicationPageData(
      contest: contest,
      publication: publication,
      policy: policy,
    );
  }

  /// The saved public update policy. Only the configuration is read, and a
  /// failed read leaves the policy unset rather than failing the page.
  static Future<PublicUpdateMode?> _policy(ApiClient client, Id id) async {
    try {
      final configuration = await MatrixPageData.latestConfiguration(
        client,
        id,
      );
      return configuration?.config.coreOptions.publicUpdateMode;
    } on Object {
      return null;
    }
  }

  @override
  List<Object?> get props => [contest, publication, policy];
}
