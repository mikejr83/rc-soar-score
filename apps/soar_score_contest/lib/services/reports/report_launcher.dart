import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a launch ended up.
enum LaunchOutcome {
  /// Opened in its own browser tab.
  newTab,

  /// The browser blocked the new tab. The page offers Open here instead.
  blocked,

  /// Opened by navigating this window, with a way back.
  inPlace,
}

/// Opens a path of the app so the contest application is not blocked: in its
/// own browser tab on the web, in place with a way back on native (a second
/// native window is not built).
abstract class ReportLauncher {
  const ReportLauncher();

  /// Opens [path] (a router location). An in-place launch adds `back=1` so
  /// the opened page can offer a way back.
  Future<LaunchOutcome> open(BuildContext context, String path);

  /// Opens [path] in this window, for the Open here fallback.
  void openHere(BuildContext context, String path);
}

/// The platform launcher: a new tab on the web, in place elsewhere.
class PlatformReportLauncher extends ReportLauncher {
  const PlatformReportLauncher();

  /// The path with `back=1`, which tells the viewer it was opened in place.
  static String inPlacePath(String path) {
    final uri = Uri.parse(path);
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'back': '1'})
        .toString();
  }

  @override
  Future<LaunchOutcome> open(BuildContext context, String path) async {
    if (!kIsWeb) {
      openHere(context, path);
      return LaunchOutcome.inPlace;
    }
    // The router uses the hash strategy, so the route lives in the fragment.
    final base = Uri.base;
    final url = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
      fragment: path,
    );
    final opened = await launchUrl(url, webOnlyWindowName: '_blank');
    return opened ? LaunchOutcome.newTab : LaunchOutcome.blocked;
  }

  @override
  void openHere(BuildContext context, String path) =>
      context.go(inPlacePath(path));
}

/// Opens a path in this window, with a way back, on every platform. The
/// end-to-end web build uses it because a journey cannot drive a second
/// browser tab.
class InPlaceReportLauncher extends PlatformReportLauncher {
  const InPlaceReportLauncher();

  @override
  Future<LaunchOutcome> open(BuildContext context, String path) async {
    openHere(context, path);
    return LaunchOutcome.inPlace;
  }
}

/// The launcher the Reports page and the report viewer use unless one is
/// passed to them. The web build made for end-to-end tests (`SOAR_SCORE_E2E`,
/// never a release build) opens reports in place with [InPlaceReportLauncher].
abstract final class ReportLaunchers {
  // Const on purpose: on the web `bool.fromEnvironment` reads the define only
  // in a constant expression and otherwise answers false.
  static const bool _e2eBuild =
      bool.fromEnvironment('SOAR_SCORE_E2E') && !kReleaseMode;

  static final ReportLauncher current = forBuild(e2e: _e2eBuild);

  /// The launcher for a build that is, or is not, the end-to-end build.
  static ReportLauncher forBuild({required bool e2e}) =>
      e2e ? InPlaceReportLauncher() : PlatformReportLauncher();
}
