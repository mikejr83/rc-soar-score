import 'package:soar_score_core/soar_score_core.dart' as core;

/// Fixed ids for the demo data, so loading it twice names the same rows.
///
/// Each id is `019c0000-0000-7000-8000-0000` followed by a four digit kind, a
/// two digit [major] and a two digit [minor] number in hexadecimal.
abstract final class DemoIds {
  static core.Id profile(int pilot) => _id('e000', 0, pilot);

  static core.Id contest(int contest) => _id('d000', 0, contest);

  static core.Id participation(int contest, int pilot) =>
      _id('f000', contest, pilot);

  /// The [n]th model of a pilot's profile.
  static core.Id model(int pilot, int n) => _id('a100', pilot, n);

  /// The [n]th model link of a pilot in a contest.
  static core.Id modelLink(int contest, int pilot, int n) =>
      _id('a200', contest, pilot * 4 + n);

  static core.Id team(int contest, int team) => _id('c100', contest, team);

  static core.Id membership(int contest, int pilot) =>
      _id('c200', contest, pilot);

  static core.Id matrix(int contest) => _id('b000', contest, 0);

  static core.Id _id(String kind, int major, int minor) {
    String two(int n) => n.toRadixString(16).padLeft(2, '0');
    return core.Id.parse(
      '019c0000-0000-7000-8000-0000$kind${two(major)}${two(minor)}',
    );
  }
}
