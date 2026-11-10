import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_pilot_invitation_source.dart';
import '../support/participants_page_support.dart';

Finder _check(int n) => find.descendant(
  of: find.byKey(ValueKey('row-${personParticipationId(n).value}')),
  matching: find.byType(Checkbox),
);

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('invitations-menu')));
  await tester.pumpAndSettle();
}

void main() {
  late PilotInvitationSource original;
  setUp(() => original = PilotInvitationSources.current);
  tearDown(() => PilotInvitationSources.current = original);

  Finder rowAction(String action, int n) => find.byKey(
    ValueKey('participant-$action-${personParticipationId(n).value}'),
  );

  Future<void> openRow(WidgetTester tester, int n) async {
    await tester.ensureVisible(rowAction('actions', n));
    await tester.tap(rowAction('actions', n));
    await tester.pumpAndSettle();
  }

  testWidgets('no selection has no toolbar remove or invitation controls', (
    tester,
  ) async {
    PilotInvitationSources.current = FakePilotInvitationSource();
    await pumpParticipantsPage(tester, ParticipantsServer());
    expect(find.byKey(const ValueKey('remove-participants')), findsNothing);
    expect(find.byKey(const ValueKey('invitations-menu')), findsNothing);
    expect(find.byKey(const ValueKey('invitations-send')), findsNothing);
    await tester.tap(_check(1));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('participants-bulk-bar')),
        matching: find.byKey(const ValueKey('invitations-menu')),
      ),
      findsOneWidget,
    );
    await _openMenu(tester);
    expect(
      find.text(AppLocalizationsEn().participantActionSend),
      findsOneWidget,
    );
    expect(
      find.text(AppLocalizationsEn().participantActionCopy),
      findsOneWidget,
    );
  });

  testWidgets(
    'row send targets that pilot without changing a different selection',
    (tester) async {
      final source = FakePilotInvitationSource();
      PilotInvitationSources.current = source;
      await pumpParticipantsPage(tester, ParticipantsServer());
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await openRow(tester, 1);
      expect(
        tester.widget<MenuItemButton>(rowAction('copy', 1)).onPressed,
        isNull,
      );
      await tester.tap(rowAction('send', 1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();
      expect(source.sent, [
        [personParticipationId(1)],
      ]);
      expect(tester.widget<Checkbox>(_check(1)).value, isFalse);
      expect(tester.widget<Checkbox>(_check(2)).value, isTrue);
      await openRow(tester, 1);
      expect(
        tester.widget<MenuItemButton>(rowAction('send', 1)).onPressed,
        isNull,
      );
      expect(
        tester.widget<MenuItemButton>(rowAction('copy', 1)).onPressed,
        isNotNull,
      );
    },
    variant: TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'row removal confirms only its target and preserves another selection',
    (tester) async {
      final server = ParticipantsServer();
      await pumpParticipantsPage(tester, server);
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await openRow(tester, 1);
      await tester.tap(rowAction('remove', 1));
      await tester.pumpAndSettle();
      expect(server.removals, isEmpty);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(_check(2)).value, isTrue);
      await openRow(tester, 1);
      await tester.tap(rowAction('remove', 1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();
      expect(server.removals, [personParticipationId(1)]);
      expect(tester.widget<Checkbox>(_check(2)).value, isTrue);
    },
  );

  testWidgets(
    'row menus disable removal for flights and locked administration',
    (tester) async {
      for (final server in [
        ParticipantsServer(
          state: LifecycleState.running,
          drawn: true,
          withScores: true,
        ),
        ParticipantsServer(lock: AdminLock.locked),
        ParticipantsServer(state: LifecycleState.completed, drawn: true),
      ]) {
        await pumpParticipantsPage(tester, server);
        await openRow(tester, 1);
        expect(
          tester.widget<MenuItemButton>(rowAction('remove', 1)).onPressed,
          isNull,
        );
        await tester.tap(rowAction('actions', 1));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('narrow card menu copies its own URL without selection', (
    tester,
  ) async {
    final link = 'https://x.test/one';
    PilotInvitationSources.current = FakePilotInvitationSource(
      links: {personParticipationId(1).value: link},
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      size: const Size(700, 1400),
    );
    await openRow(tester, 1);
    await tester.tap(rowAction('copy', 1));
    await tester.pumpAndSettle();
    expect(copied, link);
    expect(find.byKey(const ValueKey('participants-bulk-bar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'row menu disables invitation actions for non-pilots and retired pilots',
    (tester) async {
      PilotInvitationSources.current = FakePilotInvitationSource(
        links: {personParticipationId(1).value: 'https://x.test/one'},
      );
      await pumpParticipantsPage(tester, ParticipantsServer(retiredPilot: 1));
      for (final n in [1, 5]) {
        await openRow(tester, n);
        expect(
          tester.widget<MenuItemButton>(rowAction('send', n)).onPressed,
          isNull,
        );
        expect(
          tester.widget<MenuItemButton>(rowAction('copy', n)).onPressed,
          isNull,
        );
        await tester.tap(rowAction('actions', n));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('row invitation actions stay disabled until invitations load', (
    tester,
  ) async {
    final gate = Completer<void>();
    PilotInvitationSources.current = FakePilotInvitationSource(readGate: gate);
    await pumpParticipantsPage(tester, ParticipantsServer());
    await openRow(tester, 1);
    expect(
      tester.widget<MenuItemButton>(rowAction('send', 1)).onPressed,
      isNull,
    );
    expect(
      tester.widget<MenuItemButton>(rowAction('copy', 1)).onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<MenuItemButton>(rowAction('send', 1)).onPressed,
      isNotNull,
    );
  });

  testWidgets('an invitation in flight disables sends in all row menus', (
    tester,
  ) async {
    final gate = Completer<void>();
    final source = FakePilotInvitationSource(sendGate: gate);
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await openRow(tester, 1);
    await tester.tap(rowAction('send', 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await openRow(tester, 2);
    expect(
      tester.widget<MenuItemButton>(rowAction('send', 2)).onPressed,
      isNull,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(source.sent, [
      [personParticipationId(1)],
    ]);
  });

  testWidgets('multiple selection sends only eligible pilots without links', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(
      links: {personParticipationId(1).value: 'https://x.test/one'},
    );
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    for (final n in [1, 2, 5]) {
      await tester.tap(_check(n));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invitations-menu')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();
    expect(source.sent, [
      [personParticipationId(2)],
    ]);
  });
}
