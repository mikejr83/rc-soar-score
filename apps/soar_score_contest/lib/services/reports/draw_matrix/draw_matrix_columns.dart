import 'draw_matrix_data.dart';
import 'draw_matrix_options.dart';
import 'draw_matrix_style.dart';

/// The columns the Draw Matrix can carry, in table order.
enum DrawMatrixColumnId {
  lane,
  name,
  team,
  number,
  className,
  club,
  fai,
  national,
}

/// One column of the table: its heading, width and how its text sits.
class DrawMatrixColumn {
  const DrawMatrixColumn({
    required this.id,
    required this.title,
    required this.width,
    required this.alignRight,
    required this.wraps,
  });

  final DrawMatrixColumnId id;
  final String title;
  final double width;
  final bool alignRight;

  /// Text may run to more than one line; a fixed numeric column does not.
  final bool wraps;

  /// What [pilot] shows in this column; empty when they have no value.
  String textOf(DrawMatrixPilot pilot) => switch (id) {
    DrawMatrixColumnId.lane => pilot.lane?.toString() ?? '',
    DrawMatrixColumnId.name => pilot.name,
    DrawMatrixColumnId.team => pilot.team ?? '',
    DrawMatrixColumnId.number => pilot.number?.toString() ?? '',
    DrawMatrixColumnId.className => pilot.className ?? '',
    DrawMatrixColumnId.club => pilot.club ?? '',
    DrawMatrixColumnId.fai => pilot.faiId ?? '',
    DrawMatrixColumnId.national => pilot.nationalId ?? '',
  };

  /// Chooses the columns for a table [width] px wide. A column that does not
  /// apply is left out and the pilot column takes the room.
  ///
  /// Lane, number, class and the IDs have fixed widths. Pilot, team and club
  /// share what is left (3 : 1.5 : 1.8); team and club stop at their widest
  /// useful size and hand the surplus on.
  static List<DrawMatrixColumn> plan({
    required DrawMatrixOptions options,
    required DrawMatrixStyle style,
    required double width,
    required bool lanes,
    required bool teams,
    required bool numbers,
    required bool classes,
  }) {
    final fixed = <DrawMatrixColumnId, double>{};
    final flex = <DrawMatrixColumnId, ({double share, double? max})>{};
    final order = <DrawMatrixColumnId>[];
    final titles = <DrawMatrixColumnId, String>{};
    void addFixed(DrawMatrixColumnId id, String title, double w) {
      fixed[id] = w;
      order.add(id);
      titles[id] = title;
    }

    void addFlex(
      DrawMatrixColumnId id,
      String title,
      double share,
      double? max,
    ) {
      flex[id] = (share: share, max: max);
      order.add(id);
      titles[id] = title;
    }

    if (lanes) addFixed(DrawMatrixColumnId.lane, 'Lane', style.laneWidth);
    addFlex(DrawMatrixColumnId.name, 'Pilot', 3, null);
    if (teams) {
      if (style.teamFixed case final w?) {
        addFixed(DrawMatrixColumnId.team, 'Team', w);
      } else {
        addFlex(DrawMatrixColumnId.team, 'Team', 1.5, style.teamMax);
      }
    }
    if (numbers) addFixed(DrawMatrixColumnId.number, 'No.', style.numberWidth);
    if (classes) {
      addFixed(DrawMatrixColumnId.className, 'Class', style.classWidth);
    }
    if (options.showClub) {
      addFlex(DrawMatrixColumnId.club, 'Club', 1.8, style.clubMax);
    }
    if (options.showFai) addFixed(DrawMatrixColumnId.fai, 'FAI ID', 92);
    if (options.showNational) {
      addFixed(DrawMatrixColumnId.national, 'National ID', 108);
    }

    var room = width - fixed.values.fold(0.0, (a, b) => a + b);
    final open = [...flex.keys];
    // A column held at its maximum gives the rest back to the others.
    var again = true;
    final widths = <DrawMatrixColumnId, double>{};
    while (again) {
      again = false;
      final total = open.fold(0.0, (a, id) => a + flex[id]!.share);
      for (final id in open) {
        final max = flex[id]!.max;
        if (max != null && room * flex[id]!.share / total > max) {
          widths[id] = max;
          room -= max;
          open.remove(id);
          again = true;
          break;
        }
      }
    }
    final total = open.fold(0.0, (a, id) => a + flex[id]!.share);
    var used = 0.0;
    for (var i = 0; i < open.length; i++) {
      final id = open[i];
      final w = i == open.length - 1
          ? room - used
          : (room * flex[id]!.share / total).floorToDouble();
      widths[id] = w;
      used += w;
    }
    return [
      for (final id in order)
        DrawMatrixColumn(
          id: id,
          title: titles[id]!,
          width: fixed[id] ?? widths[id]!,
          alignRight:
              id == DrawMatrixColumnId.lane || id == DrawMatrixColumnId.number,
          wraps: flex.containsKey(id) || id == DrawMatrixColumnId.team,
        ),
    ];
  }
}
