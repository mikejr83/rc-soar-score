import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_codec.dart';

import '../../support/rich_contest_draft.dart';

void main() {
  Object? throughJson(Object? data) => jsonDecode(jsonEncode(data));

  test('a draft with every field set survives a JSON round trip', () {
    final draft = richDraft();

    final restored = ContestDraftCodec.decode(
      throughJson(ContestDraftCodec.encode(draft)),
    );

    expect(
      jsonEncode(ContestDraftCodec.encode(restored)),
      jsonEncode(ContestDraftCodec.encode(draft)),
    );
    expect(restored.name, 'Gator Cup F5J');
    expect(restored.source!.contest.name, draft.source!.contest.name);
    expect(restored.source!.pilots.single.name, 'Avery Brooks');
    expect(restored.participants.single.team, 'Gators');
    expect(restored.scoring!.secondDrop, 'x');
    expect(restored.draw.seededRounds, '2');
    expect(restored.visitedThrough, 5);
  });

  test('a new draft round trips and stays blank', () {
    final restored = ContestDraftCodec.decode(
      throughJson(ContestDraftCodec.encode(const ContestDraft())),
    );

    expect(restored.isBlank, isTrue);
  });

  test('data it cannot read is a FormatException, never a draft', () {
    final good = Map<String, Object?>.from(
      throughJson(ContestDraftCodec.encode(richDraft()))! as Map,
    );

    for (final bad in <Object?>[
      null,
      'text',
      <String, Object?>{},
      {...good, 'copy_mode': 'someNewMode'},
      {...good, 'participants': 'many'},
      {...good, 'visited_through': '5'},
    ]) {
      expect(
        () => ContestDraftCodec.decode(bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });
}
