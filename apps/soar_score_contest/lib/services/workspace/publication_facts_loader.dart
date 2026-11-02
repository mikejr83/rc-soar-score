import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'publication_facts.dart';

/// Reads the director's view of a contest's publication.
abstract final class PublicationFactsLoader {
  /// The publication of [id] as [PublicationFacts]: not published for a 404,
  /// unsupported when the server does not publish contests (409
  /// `publishing_not_available`), unknown for any other failure.
  static Future<PublicationFacts> load(ApiClient client, Id id) async {
    try {
      return PublicationFacts.fromJson(await client.publication(id));
    } on ApiHttpError catch (error) {
      if (error.statusCode == 404) {
        return PublicationFacts.notPublished;
      }
      if (error.statusCode == 409 &&
          error.error?.code == 'publishing_not_available') {
        return PublicationFacts.unsupported;
      }
    } on Object {
      // Falls through to unknown.
    }
    return PublicationFacts.unknown;
  }
}
