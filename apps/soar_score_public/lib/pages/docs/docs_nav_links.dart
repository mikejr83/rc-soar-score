import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Identity provider registration page.
// TODO(#21): real URL once the identity provider is set up.
const String registerUrl = 'https://example.com/register';

/// Offline (Windows) application download.
// TODO(#222): real URL once the Windows release download exists.
const String downloadUrl = 'https://example.com/download';

/// The navigation items of the docs landing page, also shown on the docs
/// not-found page (plan/ui/public-site/docs-help.md).
class DocsNavLinks extends StatelessWidget {
  const DocsNavLinks({super.key});

  @override
  Widget build(BuildContext context) {
    ListTile route(String title, String path) => ListTile(
      title: Text(title),
      subtitle: Text(path),
      onTap: () => context.go(path),
    );
    // External links are shown only; opening them is wired with the real URLs.
    ListTile external(String title, String url) =>
        ListTile(title: Text(title), subtitle: Text(url));

    return Column(
      children: [
        external('Register for an account', registerUrl),
        external('Download the offline application', downloadUrl),
        route('Search contests', '/results/contests'),
        route('Contest Director Getting Started', '/docs/competitions'),
        route('Help Me Enter My Score', '/docs/participant-scoring'),
        route('I Need An Account?', '/docs/user-accounts'),
        route('Finding Contests and Results', '/docs/contests-and-scores'),
        route('Request Support', '/support'),
      ],
    );
  }
}
