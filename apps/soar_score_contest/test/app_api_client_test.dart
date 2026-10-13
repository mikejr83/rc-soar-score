import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/platform/app_bootstrap.dart';

/// The `ApiClient` the pumped tree exposes via `ApiClientInherited`, if any.
ApiClient? _exposedClient(WidgetTester tester) {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) {
    return null;
  }
  ApiClient? found;
  void visit(Element element) {
    element.visitChildren((child) {
      final widget = child.widget;
      if (widget is ApiClientInherited && found == null) {
        found = widget.client;
      } else {
        visit(child);
      }
    });
  }

  visit(root);
  return found;
}

/// `AppBootstrap` stand-in for widget tests: the real native bootstrap starts
/// an HTTP server and a SQLite database, which widget tests do not need.
class _TestBootstrap implements AppBootstrap {
  @override
  void remoteReachabilityChanged({required bool reachable}) {}

  _TestBootstrap(this._client);

  final ApiClient _client;
  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _client;

  @override
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      _client.close();
    }
  }
}

void main() {
  testWidgets('exposes the bootstrapped client to the widget tree', (
    WidgetTester tester,
  ) async {
    final client = ApiClient(baseUrl: Uri.parse('http://localhost:8080'));
    final bootstrap = _TestBootstrap(client);
    addTearDown(bootstrap.close);

    await tester.pumpWidget(SoarScoreContestApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    expect(_exposedClient(tester), same(client));
  });

  testWidgets('leaves the client unexposed when no bootstrap is provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(_exposedClient(tester), isNull);
  });

  testWidgets('closes the bootstrap when the app is disposed', (
    WidgetTester tester,
  ) async {
    var closeCalled = false;
    final bootstrap = _ClosingTestBootstrap(() async {
      closeCalled = true;
    });
    addTearDown(bootstrap.close);

    await tester.pumpWidget(SoarScoreContestApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox()); // replace the app: dispose fires
    await tester.pumpAndSettle();

    expect(closeCalled, isTrue);
  });
}

class _ClosingTestBootstrap implements AppBootstrap {
  @override
  void remoteReachabilityChanged({required bool reachable}) {}

  _ClosingTestBootstrap(this._close);

  final Future<void> Function() _close;

  @override
  ApiClient get apiClient =>
      ApiClient(baseUrl: Uri.parse('http://localhost:8080'));

  @override
  ApiClient get remoteApiClient =>
      ApiClient(baseUrl: Uri.parse('http://localhost:8080'));

  @override
  Future<void> close() => _close();
}
