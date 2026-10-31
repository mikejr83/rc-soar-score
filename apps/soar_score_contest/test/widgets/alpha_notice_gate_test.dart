import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/services/alpha_notice/alpha_notice_key.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';
import 'package:soar_score_contest/widgets/alpha_notice_gate.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

LocalUiStore _store() => BackendLocalUiStore(MemoryLocalUiBackend());

final _t0 = DateTime.utc(2026, 10, 31, 12);

Widget _host({
  required bool enabled,
  LocalUiStore? store,
  DateTime Function()? now,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: AlphaNoticeGate(
    enabled: enabled,
    store: store,
    now: now ?? DateTime.now,
    child: Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: () {}, child: const Text('Behind')),
      ),
    ),
  ),
);

final _continue = find.widgetWithText(FilledButton, 'Continue');

/// Ticks the acknowledgement, scrolling to it first on a short window.
Future<void> _toggleAcknowledge(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(CheckboxListTile));
  await tester.pump();
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
}

Future<void> _acknowledge(WidgetTester tester) async {
  await _toggleAcknowledge(tester);
  await tester.ensureVisible(_continue);
  await tester.pump();
  await tester.tap(_continue);
  await tester.pump();
}

void main() {
  testWidgets('shows the warning and blocks the app until acknowledged', (
    tester,
  ) async {
    await tester.pumpWidget(_host(enabled: true));

    expect(find.text('Alpha release'), findsOneWidget);
    expect(
      find.textContaining('should not expect this application to store'),
      findsOneWidget,
    );
    expect(find.textContaining('manual checks'), findsOneWidget);
    expect(find.textContaining('pilot self-scoring'), findsOneWidget);
    expect(find.textContaining('primary method'), findsOneWidget);
    expect(tester.widget<FilledButton>(_continue).onPressed, isNull);

    // The app underneath does not receive taps.
    await tester.tap(find.text('Behind'), warnIfMissed: false);

    await _toggleAcknowledge(tester);
    expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);

    await tester.tap(_continue);
    await tester.pump();

    expect(find.text('Alpha release'), findsNothing);
    expect(find.text('Behind'), findsOneWidget);
  });

  testWidgets('the checkbox can be cleared again', (tester) async {
    await tester.pumpWidget(_host(enabled: true));

    await _toggleAcknowledge(tester);
    await _toggleAcknowledge(tester);

    expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
  });

  testWidgets('is not shown when disabled', (tester) async {
    await tester.pumpWidget(_host(enabled: false));

    expect(find.text('Alpha release'), findsNothing);
    expect(find.text('Behind'), findsOneWidget);
  });

  testWidgets('returns on the next launch', (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    await _acknowledge(tester);
    expect(find.text('Alpha release'), findsNothing);

    // A new launch is a new app state.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(enabled: true));

    expect(find.text('Alpha release'), findsOneWidget);
  });

  group('remembered acknowledgement', () {
    testWidgets('stays quiet on a new launch within 24 hours', (tester) async {
      final store = _store();
      await tester.pumpWidget(
        _host(enabled: true, store: store, now: () => _t0),
      );
      await tester.pump();
      expect(find.text('Alpha release'), findsOneWidget);
      await _acknowledge(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _host(
          enabled: true,
          store: store,
          now: () => _t0.add(const Duration(hours: 23)),
        ),
      );
      await tester.pump();

      expect(find.text('Alpha release'), findsNothing);
      expect(find.text('Behind'), findsOneWidget);
    });

    testWidgets('returns after 24 hours', (tester) async {
      final store = _store();
      await store.set(localUiAccountId, alphaNoticeAcknowledgedKey, _t0);

      await tester.pumpWidget(
        _host(
          enabled: true,
          store: store,
          now: () => _t0.add(const Duration(hours: 24)),
        ),
      );
      await tester.pump();

      expect(find.text('Alpha release'), findsOneWidget);
    });

    testWidgets('shows with nothing stored and does not flash while loading', (
      tester,
    ) async {
      final store = _store();
      await store.set(localUiAccountId, alphaNoticeAcknowledgedKey, _t0);

      await tester.pumpWidget(
        _host(enabled: true, store: store, now: () => _t0),
      );
      // Before the stored time is read the card is not shown.
      expect(find.text('Alpha release'), findsNothing);
      await tester.pump();
      expect(find.text('Alpha release'), findsNothing);
    });

    testWidgets('a time in the future counts as not acknowledged', (
      tester,
    ) async {
      final store = _store();
      await store.set(
        localUiAccountId,
        alphaNoticeAcknowledgedKey,
        _t0.add(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        _host(enabled: true, store: store, now: () => _t0),
      );
      await tester.pump();

      expect(find.text('Alpha release'), findsOneWidget);
    });
  });

  testWidgets('covers the landing page of the app when opted in', (
    tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp(alphaNotice: true));
    await tester.pumpAndSettle();

    expect(find.text('Alpha release'), findsOneWidget);
    expect(find.text('Sign in').hitTestable(), findsNothing);

    await _acknowledge(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.text('Sign in').hitTestable(), findsOneWidget);
  });

  testWidgets('the app does not show it unless opted in', (tester) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('Alpha release'), findsNothing);
  });

  for (final size in const [Size(360, 400), Size(800, 600)]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} with large '
        'text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _host(enabled: true),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_continue, findsOneWidget);
    });
  }
}
