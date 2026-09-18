import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix/matrix_config_panel.dart';
import 'matrix/matrix_results_view.dart';


class MatrixCreationPage extends StatefulWidget {
  const MatrixCreationPage({super.key});

  @override
  State<MatrixCreationPage> createState() => _MatrixCreationPageState();
}
class _MatrixCreationPageState extends State<MatrixCreationPage> {
  int pilotCount = 12;
  int groupsPerRound = 3;
  int roundsRequested = 5;
  bool useTeams = false;
  int teamsCount = 3;

  DrawResult? result;
  Map<String, String> pilotNames = {};
  bool isGenerating = false;
  String? error;
  void _onGenerate() {
    setState(() {
      isGenerating = true;
      result = null;
      error = null;
      pilotNames = {};
    });

    final pilotIds = <String>[];
    for (int i = 0; i < pilotCount; i++) {
      pilotIds.add('pilot-$i');
      pilotNames['pilot-$i'] = 'Pilot ${i + 1}';
    }

    final pilotTeams = <String, int>{};
    if (useTeams) {
      final pilotsPerTeam = pilotCount ~/ teamsCount;
      for (int i = 0; i < pilotCount; i++) {
        pilotTeams['pilot-$i'] = i ~/ pilotsPerTeam;
      }
    }

    Future.microtask(() {
      try {
        final service = MatrixDrawService(seed: 42);
        final drawResult = service.generate(
          pilotIds: pilotIds,
          pilotTeams: pilotTeams,
          groupsPerRound: groupsPerRound,
          roundsRequested: roundsRequested,
          temperature: 500,
          coolingRate: 0.9998,
          maxIterations: 5000,
        );

        setState(() {
          result = drawResult;
          isGenerating = false;
        });
      } catch (e) {
        setState(() {
          error = 'Error generating matrix: $e';
          isGenerating = false;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Creation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate Flight Matrix',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: MatrixConfigPanel(
                          pilotCount: pilotCount,
                          groupsPerRound: groupsPerRound,
                          roundsRequested: roundsRequested,
                          useTeams: useTeams,
                          teamsCount: teamsCount,
                          onPilotCountChanged: (v) =>
                              setState(() => pilotCount = v),
                          onGroupsChanged: (v) =>
                              setState(() => groupsPerRound = v),
                          onRoundsChanged: (v) =>
                              setState(() => roundsRequested = v),
                          onUseTeamsChanged: (v) =>
                              setState(() => useTeams = v),
                          onTeamsCountChanged: (v) =>
                              setState(() => teamsCount = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: result != null
                            ? MatrixResultsView(
                                result: result!,
                                pilotNames: pilotNames,
                              )
                            : isGenerating
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Generating matrix...'),
                                      ],
                                    ),
                                  )
                                : error != null
                                    ? Center(
                                        child: Text(error!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(color: Colors.red)),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.grid_on,
                                                size: 64,
                                                color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text('Configure and generate to see results'),
                                          ],
                                        ),
                                      ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : _onGenerate,
                  icon: const Icon(Icons.refresh),
                  label: Text(isGenerating
                      ? 'Generating...'
                      : 'Generate Matrix'),
                ),
                const SizedBox(width: 8),
                if (result != null)
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      result = null;
                    }),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
