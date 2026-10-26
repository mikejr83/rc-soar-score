import '../../enums/lane_mode.dart';
import '../../models/id.dart';
import 'basic_draw.dart';
import 'seeded_random.dart';

/// Draws one seeded round (`SeededManOnMan`): pilots are split into tiers by
/// their standing and the leaders fly last.
///
/// The tiers are as even as the groups: with `b = pilots ~/ groups` and
/// `r = pilots % groups`, groups 1 to `r` hold `b + 1` pilots and the rest
/// hold `b`. Group 1 takes the lowest-ranked tier and the last group the
/// highest (`plan/tickets/pre-implementation/026-matrix-seeded-round-order.md`).
/// Pilots tied on place, and pilots without a standing (they rank below every
/// pilot that has one), are ordered by [random], so a seed reproduces the
/// round. Team protection does not apply to a seeded draw.
class SeededDraw {
  const SeededDraw();

  /// The groups of one round: `result[group]` lists the slots of that group,
  /// with lanes when [laneMode] is `random`.
  ///
  /// [places] maps a participation to its place in the standings (1 is the
  /// leader). Throws an [ArgumentError] when [groupsPerRound] is outside 1 to
  /// the number of pilots.
  List<List<DrawSlot>> generate({
    required List<DrawPilot> pilots,
    required Map<Id, int> places,
    required int groupsPerRound,
    required LaneMode laneMode,
    required SeededRandom random,
  }) {
    if (groupsPerRound < 1 || groupsPerRound > pilots.length) {
      throw ArgumentError.value(
        groupsPerRound,
        'groupsPerRound',
        'must be between 1 and the number of pilots (${pilots.length})',
      );
    }
    // Best first; shuffle first so equal places end up in a random order (the
    // sort is stable).
    final worstPlace = places.values.fold(0, (a, b) => a > b ? a : b) + 1;
    final shuffled = random.shuffle([...pilots]);
    final ranked = [for (var i = 0; i < shuffled.length; i++) (i, shuffled[i])]
      ..sort((a, b) {
        final byPlace = (places[a.$2.participationId] ?? worstPlace).compareTo(
          places[b.$2.participationId] ?? worstPlace,
        );
        return byPlace != 0 ? byPlace : a.$1.compareTo(b.$1);
      });

    final base = pilots.length ~/ groupsPerRound;
    final extra = pilots.length % groupsPerRound;
    // Fill from the last group (the leaders) back to group 1.
    final groups = List<List<DrawSlot>>.filled(groupsPerRound, const []);
    var next = 0;
    for (var g = groupsPerRound; g >= 1; g--) {
      final size = g <= extra ? base + 1 : base;
      final members = [
        for (final (_, pilot) in ranked.skip(next).take(size)) pilot,
      ];
      next += size;
      random.shuffle(members);
      groups[g - 1] = [
        for (var i = 0; i < members.length; i++)
          DrawSlot(members[i], laneMode == LaneMode.random ? i + 1 : null),
      ];
    }
    return groups;
  }
}
