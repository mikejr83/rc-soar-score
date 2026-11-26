import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_pilot_invitation_source.dart';
import '../support/participants_page_support.dart';

Finder _check(int n) => find.descendant(
  of: find.byKey(ValueKey('row-${personParticipationId(n).value}')),
  matching: find.byType(Checkbox),
);

Future<void> _closeMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('invitations-menu')));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  // The menu may still be open from an earlier look.
  if (find.byKey(const ValueKey('invitations-send')).evaluate().isNotEmpty) {
    return;
  }
  await tester.tap(find.byKey(const ValueKey('invitations-menu')));
  await tester.pumpAndSettle();
}

void main() {
  late PilotInvitationSource original;
  setUp(() => original = PilotInvitationSources.current);
  tearDown(() => PilotInvitationSources.current = original);

  testWidgets('sends invitations for the selected pilots after confirming', (
    tester,
  ) async {
    final source = FakePilotInvitationSource();
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('invitations-menu')), findsNothing);
    expect(find.text('Send invitations (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    expect(find.text('Send invitations?'), findsOneWidget);
    // Sending also emails the pilots who have an address.
    expect(find.textContaining('emailed their link'), findsWidgets);
    expect(find.textContaining('Nobody is emailed'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, [
      [personParticipationId(1), personParticipationId(2)],
    ]);
    expect(
      find.text('2 invitations sent. Nobody was emailed.'),
      findsOneWidget,
    );
  });

  testWidgets('the confirmation lists the pilots by name, not address', (
    tester,
  ) async {
    PilotInvitationSources.current = FakePilotInvitationSource();
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();

    final names = tester.widget<Text>(
      find.byKey(const ValueKey('cards-send-names')),
    );
    expect(names.data, 'Ann Lee, Bo Ray');
    expect(find.textContaining('@'), findsNothing);
    expect(find.byKey(const ValueKey('cards-send-again-note')), findsNothing);
  });

  testWidgets('sending again says who was emailed before, then emails', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(
      links: {
        personParticipationId(1).value: 'https://x.test/1',
        personParticipationId(2).value: 'https://x.test/2',
      },
      emailStatus: {personParticipationId(1).value: 'accepted'},
      email: (ids) => InvitationEmailReport(
        kinds: {for (final id in ids) id.value: InvitationEmailKind.emailed},
      ),
    );
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '1 of these pilots was emailed before and will be emailed again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, [
      [personParticipationId(1), personParticipationId(2)],
    ]);
    expect(find.text('2 invitations sent. 2 pilots emailed.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('invitations-result-dialog')),
      findsNothing,
    );
  });

  testWidgets('pilots whose email did not go out are listed by name', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(
      email: (ids) => InvitationEmailReport(
        kinds: {
          ids[0].value: InvitationEmailKind.emailed,
          ids[1].value: InvitationEmailKind.notSent,
        },
      ),
    );
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const ValueKey('invitations-result-dialog'));
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Bo Ray')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Ann Lee')),
      findsNothing,
    );
    expect(find.textContaining('Copy these pilots'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invitations-result-close')));
    await tester.pumpAndSettle();
    expect(find.text('2 invitations sent. 1 pilot emailed.'), findsOneWidget);
    // The links exist whatever happened to the email.
    expect(source.links, hasLength(2));
  });

  testWidgets('lost answers never say that nobody was emailed', (tester) async {
    final source = FakePilotInvitationSource(
      email: (ids) => InvitationEmailReport(
        kinds: {for (final id in ids) id.value: InvitationEmailKind.unknown},
      ),
    );
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-result-close')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nobody was emailed'), findsNothing);
    expect(find.textContaining('2 not confirmed'), findsOneWidget);
  });

  testWidgets('a server that cannot email says so and keeps the links', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(
      email: (_) => const InvitationEmailReport.unavailable(),
    );
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Email could not be sent right now'),
      findsOneWidget,
    );
    // Both pilots are named, though the server answered for nobody.
    final dialog = find.byKey(const ValueKey('invitations-result-dialog'));
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('Ann Lee, Bo Ray'),
      ),
      findsOneWidget,
    );
    expect(source.links, hasLength(2));
  });

  testWidgets(
    'pilots with no address are listed by name and noted in the snack bar',
    (tester) async {
      final source = FakePilotInvitationSource(
        email: (ids) => InvitationEmailReport(
          kinds: {
            ids[0].value: InvitationEmailKind.emailed,
            ids[1].value: InvitationEmailKind.noAddress,
          },
        ),
      );
      PilotInvitationSources.current = source;
      await pumpParticipantsPage(tester, ParticipantsServer());
      await tester.tap(_check(1));
      await tester.tap(_check(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invitations-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
      await tester.pumpAndSettle();

      final dialog = find.byKey(const ValueKey('invitations-result-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Bo Ray')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('invitations-result-close')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 pilot has no email address on file.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('non-flying participants are not sent invitations', (
    tester,
  ) async {
    final source = FakePilotInvitationSource();
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(5));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    final send = tester.widget<MenuItemButton>(
      find.byKey(const ValueKey('invitations-send')),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('Copy link copies the one selected pilot’s link', (tester) async {
    final link = 'https://x.test/${personParticipationId(1).value}';
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
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('invitations-copy')));
    await tester.pumpAndSettle();

    expect(copied, link);
    expect(find.text('Link copied.'), findsOneWidget);
  });

  testWidgets('Copy link is off for a pilot without an invitation', (
    tester,
  ) async {
    PilotInvitationSources.current = FakePilotInvitationSource();
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(
      tester
          .widget<MenuItemButton>(
            find.byKey(const ValueKey('invitations-copy')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('the server’s reason turns sending off', (tester) async {
    PilotInvitationSources.current = FakePilotInvitationSource(
      reason: 'Invitations can’t be sent for a completed contest.',
    );
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(
      tester
          .widget<MenuItemButton>(
            find.byKey(const ValueKey('invitations-send')),
          )
          .onPressed,
      isNull,
    );
  });

  MenuItemButton menuItem(WidgetTester tester, String key) =>
      tester.widget<MenuItemButton>(find.byKey(ValueKey(key)));

  testWidgets('Copy link needs exactly one selected row that is a pilot', (
    tester,
  ) async {
    PilotInvitationSources.current = FakePilotInvitationSource(
      links: {
        personParticipationId(1).value: 'https://x.test/1',
        personParticipationId(2).value: 'https://x.test/2',
      },
    );
    await pumpParticipantsPage(tester, ParticipantsServer());
    // A pilot plus a non-flying participant is two rows.
    await tester.tap(_check(1));
    await tester.tap(_check(5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invitations-copy')), findsNothing);
    // Everyone selected has a link, and Send sends again to the pilot.
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('invitations-send')))
          .onPressed,
      isNotNull,
    );

    // Two pilots are two rows as well.
    await tester.tap(_check(5));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invitations-copy')), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('invitations-send')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a retired pilot is marked and can still Send and Copy link', (
    tester,
  ) async {
    PilotInvitationSources.current = FakePilotInvitationSource(
      links: {personParticipationId(2).value: 'https://x.test/2'},
    );
    await pumpParticipantsPage(tester, ParticipantsServer(retiredPilot: 1));
    expect(find.text('Retired from round 2'), findsOneWidget);

    // Without a link yet, Send is offered.
    await tester.tap(_check(1));
    await tester.pumpAndSettle();
    await _openMenu(tester);
    expect(menuItem(tester, 'invitations-send').onPressed, isNotNull);
    expect(menuItem(tester, 'invitations-copy').onPressed, isNull);
  });

  testWidgets('a retired pilot with a link can copy it', (tester) async {
    PilotInvitationSources.current = FakePilotInvitationSource(
      links: {personParticipationId(1).value: 'https://x.test/1'},
    );
    await pumpParticipantsPage(tester, ParticipantsServer(retiredPilot: 1));
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(menuItem(tester, 'invitations-copy').onPressed, isNotNull);
  });

  testWidgets('a completed contest still copies a link and issues none', (
    tester,
  ) async {
    final link = 'https://x.test/${personParticipationId(1).value}';
    PilotInvitationSources.current = FakePilotInvitationSource(
      links: {personParticipationId(1).value: link},
      reason: 'Invitations can’t be sent for a completed contest.',
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
      ParticipantsServer(state: LifecycleState.completed, drawn: true),
    );
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(menuItem(tester, 'invitations-send').onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('invitations-copy')));
    await tester.pumpAndSettle();
    expect(copied, link);
  });

  testWidgets('a failed send says nothing was sent and issues nothing', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(failSend: true);
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, isEmpty);
    expect(
      find.text(
        'The invitations could not be created. Nothing was sent. Try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a send whose read-back fails reports that it worked', (
    tester,
  ) async {
    final source = FakePilotInvitationSource(failReadAfterSend: true);
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, hasLength(1));
    expect(
      find.textContaining('were created, but could not be loaded'),
      findsOneWidget,
    );
  });

  testWidgets('losing the connection turns sending off with the reason', (
    tester,
  ) async {
    final source = FakePilotInvitationSource();
    PilotInvitationSources.current = source;
    final connectivity = FakeAppConnectivity();
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      connectivity: connectivity,
    );
    await tester.tap(_check(1));
    await tester.pumpAndSettle();
    await _openMenu(tester);
    expect(menuItem(tester, 'invitations-send').onPressed, isNotNull);
    await _closeMenu(tester);
    await tester.pumpAndSettle();

    connectivity
      ..internetStatus = ConnectivityStatus.unavailable
      ..notifyListeners();
    await tester.pumpAndSettle();
    await _openMenu(tester);
    expect(menuItem(tester, 'invitations-send').onPressed, isNull);
    expect(source.sent, isEmpty);
    await _closeMenu(tester);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Tooltip &&
            (w.message ?? '').startsWith(
              'You’re offline, so invitations can’t be sent now.',
            ),
      ),
      findsOneWidget,
    );
  });
}
