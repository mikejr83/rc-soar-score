import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The public routes, served at `/public` with no sign-in:
///
/// - `GET /publications/{id}` is the current projection of a Public or
///   Unlisted publication, with pilots' display details unless redacted, and
///   standings only through the round the director allows;
/// - `GET /publications` lists the Public publications by contest start,
///   newest first, with a 30-day `summary`. Parameters: `name` and `venue`
///   (case-insensitive substrings), `from` and `to` (`yyyy-MM-dd`, inclusive
///   bounds on the start day, UTC), `today` (the caller's day; default the
///   server's UTC day), `limit` (at most 100) and `offset`. Without `to`,
///   only contests starting through the coming Sunday are listed (the
///   following Sunday when `today` is a Sunday). Unlisted ones are never
///   listed.
///
/// Both successful reads may be cached for 30 seconds ([publicCacheControl]):
/// a new publication, a delisting or a change to hidden results reaches every
/// reader within that long and no longer (#906). Errors, including the 403
/// `contest_not_visible`, are never cached (`no-store`, set by the security
/// headers middleware), so a contest that becomes visible shows at once.
///
/// Both payloads carry `contest.status`, `upcoming`, `in_progress` or
/// `completed`, worked out when the contest is read: before its start, Upcoming;
/// Completed after the director completes it or 48 hours without activity (#454).
///
/// An unknown publication is a 404. One that exists but is not shown (Delisted,
/// or with no projection yet) is a 403 `contest_not_visible`. With [enabled] false (the
/// embedded server) both routes answer 409 `publishing_not_available`.
///
/// The handlers only translate between HTTP and [PublicPublicationService].
/// How long a browser or the CDN may reuse a public read: the answer is the
/// same for everyone asking for the same thing. This is the longest a new
/// publication, a delisting or a hiding of results takes to show (#906).
const publicCacheControl = 'public, max-age=30';

Handler buildPublicHandler(Repository repository, {required bool enabled}) {
  final service = PublicPublicationService(repository);
  final router = Router();

  void requireEnabled() {
    if (!enabled) {
      throw ContestStateError(
        'publishing_not_available',
        'this server does not publish contests',
      );
    }
  }

  router.get('/publications', (Request request) async {
    requireEnabled();
    final query = request.url.queryParameters;
    final page = await service.list(
      name: query['name'] ?? '',
      venue: query['venue'] ?? '',
      from: _dayParameter(query, 'from'),
      to: _dayParameter(query, 'to'),
      today: _dayParameter(query, 'today'),
      limit: _intParameter(query, 'limit') ?? 50,
      offset: _intParameter(query, 'offset') ?? 0,
    );
    return jsonResponse(page.toJson())
        .change(headers: {'cache-control': publicCacheControl});
  });

  router.get('/publications/<id>', (Request request, String id) async {
    requireEnabled();
    final publication = await service.read(Id.parse(id));
    return jsonResponse(publication.toJson())
        .change(headers: {'cache-control': publicCacheControl});
  });

  return router.call;
}

/// A `yyyy-MM-dd` calendar day, or null when absent.
DateTime? _dayParameter(Map<String, String> query, String name) {
  final raw = query[name];
  if (raw == null || raw.isEmpty) return null;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    throw ArgumentError.value(raw, name, 'not a date (yyyy-MM-dd)');
  }
  final parsed = DateTime.tryParse('${raw}T00:00:00Z');
  if (parsed == null || _formatDay(parsed) != raw) {
    throw ArgumentError.value(raw, name, 'not a date (yyyy-MM-dd)');
  }
  return parsed;
}

String _formatDay(DateTime day) => day.toIso8601String().substring(0, 10);

int? _intParameter(Map<String, String> query, String name) {
  final raw = query[name];
  if (raw == null) return null;
  return int.tryParse(raw) ??
      (throw ArgumentError.value(raw, name, 'not a whole number'));
}
