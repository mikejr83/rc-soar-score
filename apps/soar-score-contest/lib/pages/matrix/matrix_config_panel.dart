import 'package:flutter/material.dart';

/// Panel for configuring matrix draw parameters.
class MatrixConfigPanel extends StatelessWidget {
  final int pilotCount;
  final int groupsPerRound;
  final int roundsRequested;
  final bool useTeams;
  final int teamsCount;
  final ValueChanged<int> onPilotCountChanged;
  final ValueChanged<int> onGroupsChanged;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<bool> onUseTeamsChanged;
  final ValueChanged<int> onTeamsCountChanged;

  const MatrixConfigPanel({
    super.key,
    required this.pilotCount,
    required this.groupsPerRound,
    required this.roundsRequested,
    required this.useTeams,
    required this.teamsCount,
    required this.onPilotCountChanged,
    required this.onGroupsChanged,
    required this.onRoundsChanged,
    required this.onUseTeamsChanged,
    required this.onTeamsCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilots', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: pilotCount.toDouble(),
          min: 2,
          max: 40,
          divisions: 38,
          label: pilotCount.toString(),
          onChanged: (v) => onPilotCountChanged(v.toInt()),
        ),
        const SizedBox(height: 8),
        Text('Groups per round', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: groupsPerRound.toDouble(),
          min: 1,
          max: (pilotCount ~/ 2).toDouble(),
          divisions: (pilotCount ~/ 2 - 1).clamp(1, 20),
          label: groupsPerRound.toString(),
          onChanged: (v) => onGroupsChanged(v.toInt()),
        ),
        const SizedBox(height: 8),
        Text('Rounds', style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: roundsRequested.toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          label: roundsRequested.toString(),
          onChanged: (v) => onRoundsChanged(v.toInt()),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Use teams (enable team protection)'),
          value: useTeams,
          onChanged: (v) { if (v != null) onUseTeamsChanged(v); },
          contentPadding: EdgeInsets.zero,
        ),
        if (useTeams) ...[
          const SizedBox(height: 8),
          Text('Teams', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: teamsCount.toDouble(),
            min: 2,
            max: (pilotCount ~/ 2).toDouble(),
            divisions: (pilotCount ~/ 2 - 1).clamp(1, 20),
            label: teamsCount.toString(),
            onChanged: (v) => onTeamsCountChanged(v.toInt()),
          ),
        ],
      ],
    );
  }
}