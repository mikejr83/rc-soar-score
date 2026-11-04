import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'publication_facts.dart';

/// Reads the director's view of a contest's publication.
abstract final class PublicationFactsLoader {
  /// The publication of [id] as [PublicationFacts]: not published for a 404,
  /// unsupported when the server does not publish contests (409
  /// `publishing_not_available`), unknown for any other failure.
  ///
  /// A published, not delisted publication also gets its pending delisting
  /// request, if any. A failed read of that request leaves it out: the
  /// director can still ask, and the server answers with the pending one.
  static Future<PublicationFacts> load(ApiClient client, Id id) async {
    try {
      final facts = PublicationFacts.fromJson(await client.publication(id));
      if (!facts.isPublished ||
          facts.visibility == PublicationVisibility.delisted) {
        return facts;
      }
      return facts.withPendingDelist(await _pendingDelist(client, id));
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

  static Future<DelistRequest?> _pendingDelist(ApiClient client, Id id) async {
    try {
      final latest = await client.currentDelistRequest(id);
      return latest.isPending ? latest : null;
    } on Object {
      return null;
    }
  }
}
