import 'package:flutter/material.dart';

import '../../services/matrix/team_marker.dart';
import '../matrix/team_badge.dart';

/// A team marker with the team's name, so the code is never alone.
class TeamChip extends StatelessWidget {
  const TeamChip({super.key, required this.marker});

  final TeamMarker marker;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TeamBadge(marker: marker),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          marker.name,
          style: Theme.of(context).textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
