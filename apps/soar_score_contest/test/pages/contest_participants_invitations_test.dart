import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

class _Source implements PilotInvitationSource {
  _Source({this.links = const {}, this.reason});

  Map<String, String> links;
  final String? reason;
  final sent = <List<Id>>[];

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      PilotInvitations(links: Map.of(links), sendUnavailableReason: reason);

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> ids) async {
    sent.add(ids);
    links = {
      ...links,
      for (final id in ids) id.value: 'https://x.test/${id.value}',
    };
  }
}

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

  testWidgets('sends invitations for the selected pilots after confirming', (
    tester,
  ) async {
    final source = _Source();
    PilotInvitationSources.current = source;
    await pumpParticipantsPage(tester, ParticipantsServer());
    await tester.tap(_check(1));
    await tester.tap(_check(2));
    await tester.pumpAndSettle();

    await _openMenu(tester);
    expect(find.text('Send invitations (2)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invitations-send')));
    await tester.pumpAndSettle();
    expect(find.text('Send invitations?'), findsOneWidget);
    expect(find.textContaining('Nobody is emailed'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, [
      [personParticipationId(1), personParticipationId(2)],
    ]);
    expect(
      find.text('2 invitations created. Nobody was emailed.'),
      findsOneWidget,
    );
  });

  testWidgets('non-flying participants are not sent invitations', (
    tester,
  ) async {
    final source = _Source();
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
    PilotInvitationSources.current = _Source(
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
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
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
    PilotInvitationSources.current = _Source();
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
    PilotInvitationSources.current = _Source(
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
}
