import '../../matrix/matrix_grid_model.dart';
import '../../matrix/matrix_page_data.dart';

/// One pilot's row in a group of the Draw Matrix. A value the contest does not
/// use is `null`; the report leaves its column out.
class DrawMatrixPilot {
  const DrawMatrixPilot({
    required this.name,
    this.lane,
    this.team,
    this.number,
    this.className,
    this.club,
    this.faiId,
    this.nationalId,
  });

  /// "Vargas, Elena"; a single name stands as it is.
  final String name;
  final int? lane;
  final String? team;
  final int? number;
  final String? className;
  final String? club;
  final String? faiId;
  final String? nationalId;
}

/// One group of a round, with its letter ("A").
class DrawMatrixGroup {
  const DrawMatrixGroup({required this.label, required this.pilots});

  final String label;
  final List<DrawMatrixPilot> pilots;
}

/// One drawn round with its groups in order.
class DrawMatrixRound {
  const DrawMatrixRound({required this.ordinal, required this.groups});

  final int ordinal;
  final List<DrawMatrixGroup> groups;
}

/// What the Draw Matrix is built from: the live rounds of the current matrix
/// with the pilots in each group. Read once; the round range, compact mode and
/// the extra columns are applied to it without another read.
class DrawMatrixData {
  const DrawMatrixData({required this.rounds, required this.hasLanes});

  /// Arranges [page]'s current matrix. Superseded and cancelled rounds and
  /// superseded assignments are already left out by the grid model.
  factory DrawMatrixData.of(MatrixPageData page) {
    final grid = MatrixGridModel.of(page.matrix, page.pilots);
    final profiles = {for (final p in page.profiles) p.id: p};
    final participations = {for (final p in page.participations) p.id: p};
    final classes = page.options?.classesEnabled ?? false;
    final teams = {for (final (id, marker) in page.markers.ordered) id: marker};
    DrawMatrixPilot pilot(GridSlot slot) {
      final id = slot.pilot.participationId;
      final participation = participations[id];
      final profile = profiles[participation?.participantProfileId];
      final team = teams[slot.pilot.teamId]?.name;
      return DrawMatrixPilot(
        name: profile == null
            ? slot.pilot.name
            : _listName(profile.firstName, profile.lastName),
        lane: slot.lane,
        team: page.showTeams ? team : null,
        number: slot.pilot.number,
        className: classes ? participation?.classification : null,
        club: _text(profile?.club),
        faiId: _text(profile?.faiNumber),
        nationalId: _text(profile?.nationalOrgId),
      );
    }

    return DrawMatrixData(
      hasLanes: grid.hasLanes,
      rounds: [
        for (final round in grid.rounds)
          DrawMatrixRound(
            ordinal: round.ordinal,
            groups: [
              for (var g = 0; g < round.groups.length; g++)
                DrawMatrixGroup(
                  label: groupLabel(g),
                  pilots: [for (final slot in round.groups[g]) pilot(slot)],
                ),
            ],
          ),
      ],
    );
  }

  final List<DrawMatrixRound> rounds;

  /// Whether the draw gave lanes; without them there is no Lane column.
  final bool hasLanes;

  /// Group 0 is "A", 1 is "B", and so on; past "Z" it carries on as "AA".
  static String groupLabel(int index) {
    var n = index;
    var label = '';
    do {
      label = String.fromCharCode(0x41 + n % 26) + label;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return label;
  }

  static String _listName(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    return f.isEmpty || l.isEmpty ? '$f$l' : '$l, $f';
  }

  static String? _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
