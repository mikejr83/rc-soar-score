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
    final results = await Future.wait<Object?>([
      MatrixPageData.forContest(client, contest),
      PublicationFactsLoader.load(client, id),
    ]);
    return PublicationPageData(
      contest: contest,
      publication: results[1]! as PublicationFacts,
      policy: (results[0]! as MatrixPageData).options?.publicUpdateMode,
    );
  }

  @override
  List<Object?> get props => [contest, publication, policy];
}
