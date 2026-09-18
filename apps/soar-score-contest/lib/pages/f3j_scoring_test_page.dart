import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Parse a time string in one of these formats:
/// - "600" -> 600 seconds
/// - "600.5" -> 600.5 seconds (fractional seconds)
/// - "10:00" -> 600 seconds (M:ss)
/// - "10:30.5" -> 630.5 seconds (M:ss.s)
double parseDuration(String input) {
  final trimmed = input.trim();

  // Try M:ss format with optional fractional seconds
  final colonMatch = RegExp(r'^(\d+):(\d+)(?:\.(\d+))?$').firstMatch(trimmed);
  if (colonMatch != null) {
    final minutes = int.parse(colonMatch.group(1)!);
    final seconds = int.parse(colonMatch.group(2)!);
    final fractional = colonMatch.group(3) != null
        ? double.parse('.'.padRight(2, colonMatch.group(3)![0]))
        : 0.0;
    return minutes * 60.0 + seconds + fractional;
  }

  // Plain number - treat as seconds (with optional fractional part)
  return double.parse(trimmed);
}

class F3JScoringTestScreen extends StatefulWidget {
  const F3JScoringTestScreen({super.key});

  @override
  State<F3JScoringTestScreen> createState() => _F3JScoringTestScreenState();
}

class _F3JScoringTestScreenState extends State<F3JScoringTestScreen> {
  final _workingTimeSeconds = TextEditingController(text: '600');
  final _pointsPerSecond = TextEditingController(text: '1.0');
  List<Map<String, dynamic>> pilots = [];
  String? _scoringError;
  GroupScores? _scores;
  final _pilotCountController = TextEditingController(text: '3');

  void _addPilots() {
    final count = int.tryParse(_pilotCountController.text.trim()) ?? 0;
    if (count < 1) return;

    setState(() {
      pilots = [];
      for (int i = 0; i < count; i++) {
        pilots.add({
          'id': 'pilot-$i',
          'name': 'Pilot ${i + 1}',
          'durationController': TextEditingController(text: '600'),
          'landingBonusController': TextEditingController(text: '0'),
          'zeroReason': 'none',
        });
      }
      _workingTimeSeconds.text = '600';
      _pointsPerSecond.text = '1.0';
      _scoringError = null;
      _scores = null;
    });
  }

  void _runScoring() {
    final workingTime = parseDuration(_workingTimeSeconds.text);
    final pps = double.tryParse(_pointsPerSecond.text) ?? 1.0;

    final config = ContestScoringConfig(
      discipline: Discipline.f3j,
      targetTimeSeconds: workingTime,
      f3jWorkingTimeSeconds: workingTime.toInt(),
      pointsPerSecond: pps,
      groupScoreType: GroupScoreType.normalized,
    );

    final flights = <F3JFlight>[];
    for (int i = 0; i < pilots.length; i++) {
      final pilot = pilots[i];
      final duration = parseDuration(pilot['durationController'].text);
      final landingBonus =
          int.tryParse(pilot['landingBonusController'].text) ?? 0;

      ZeroReason? zeroReason;
      if (pilot['zeroReason'] == 'outOfBounds') {
        zeroReason = OutOfBoundsLanding();
      }

      flights.add(
        F3JFlight(
          id: 'flight-$i',
          pilotId: pilot['id'],
          durationSeconds: duration,
          landingBonus: landingBonus,
          zeroReason: zeroReason,
        ),
      );
    }

    try {
      final engine = ScoringEngine();
      setState(() {
        _scores = engine.normalizeGroupScores(flights, config);
        _scoringError = null;
      });
    } catch (e) {
      setState(() {
        _scoringError = 'Scoring error: $e';
        _scores = null;
      });
    }
  }

  @override
  void dispose() {
    _workingTimeSeconds.dispose();
    _pointsPerSecond.dispose();
    _pilotCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F3J Score Testing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Pilot count and Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pilotCountController,
                    decoration:
                        const InputDecoration(labelText: 'Number of pilots'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPilots,
                  child: const Text('Add Pilots'),
                ),
              ],
            ),
          ),

          // Contest configuration
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Working time
                TextField(
                  controller: _workingTimeSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Working Time (seconds or M:ss)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Points per second
                TextField(
                  controller: _pointsPerSecond,
                  decoration: const InputDecoration(
                    labelText: 'Points Per Second',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Run Scoring button
                ElevatedButton(
                  onPressed: pilots.isEmpty ? null : _runScoring,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Run Scoring',
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 24),

                // Pilot inputs
                for (int i = 0; i < pilots.length; i++)
                  _buildPilotInput(i, pilots[i]),

                // Results
                if (_scores != null) ...[
                  const SizedBox(height: 16),
                  _buildResultsSection(),
                ],
                if (_scoringError != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Text(
        _scoringError!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildResultsSection() {
    final scores = _scores!.scores;
    final sortedScores = scores.toList()..sort((a, b) => b.groupScore
        .compareTo(a.groupScore));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scoring Results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Pilot')),
                  DataColumn(label: Text('Raw')),
                  DataColumn(label: Text('Group')),
                  DataColumn(label: Text('Status')),
                ],
                rows: sortedScores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final score = entry.value;
                  final pilotName = index < pilots.length
                      ? pilots[index]['name']
                      : 'Unknown';
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(pilotName)),
                    DataCell(Text(score.rawScore.toStringAsFixed(2))),
                    DataCell(Text(score.groupScore.toStringAsFixed(2))),
                    DataCell(Text(score.isZeroScore
                        ? score.zeroReason ?? 'Zero'
                        : 'Valid')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotInput(int index, Map<String, dynamic> pilot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pilot['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Duration (sec or M:ss)',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    controller: pilot['durationController'],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Landing Bonus',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    controller: pilot['landingBonusController'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('None'),
                    selected: pilot['zeroReason'] == 'none',
                    onSelected: (s) {
                      setState(() {
                        pilot['zeroReason'] = 'none';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('OOB'),
                    selected: pilot['zeroReason'] == 'outOfBounds',
                    onSelected: (s) {
                      setState(() {
                        pilot['zeroReason'] = 'outOfBounds';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}