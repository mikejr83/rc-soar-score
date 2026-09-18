import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'pages/score_page_selector.dart';

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
        ? double.parse('.' + colonMatch.group(3)!)
        : 0.0;
    return minutes * 60.0 + seconds + fractional;
  }
  
  // Plain number - treat as seconds (with optional fractional part)
  return double.parse(trimmed);
}

void main() {
  runApp(const ScoreSoarContest());
}

class ScoreSoarContest extends StatelessWidget {
  const ScoreSoarContest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Soar - Contest Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
      home: const ScorePageSelector(),
    );
  }
}

class F5JScoringTestScreen extends StatefulWidget {
  const F5JScoringTestScreen({super.key});

  @override
  State<F5JScoringTestScreen> createState() => _F5JScoringTestScreenState();
}

class _F5JScoringTestScreenState extends State<F5JScoringTestScreen> {
  final _targetTimeSeconds = TextEditingController(text: '600');
  final _pointsPerSecond = TextEditingController(text: '1.0');
  final _heightPenalty = TextEditingController(text: '0.5');
  final _referenceAltitude = TextEditingController(text: '200');
  final _aboveRefPenalty = TextEditingController(text: '3.0');
  String _motorRestartMode = 'allowed';
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
          'durationSeconds': '600',
          'launchAltitudeMeters': '0',
          'landingBonus': '0',
          'zeroReason': 'none',
        });
      }
      _targetTimeSeconds.text = '600';
      _pointsPerSecond.text = '1.0';
      _heightPenalty.text = '0.5';
      _referenceAltitude.text = '200';
      _aboveRefPenalty.text = '3.0';
      _motorRestartMode = 'allowed';
      _scoringError = null;
      _scores = null;
    });
  }

  void _runScoring() {
    final targetTime = parseDuration(_targetTimeSeconds.text);
    final pps = double.tryParse(_pointsPerSecond.text) ?? 1.0;
    final heightPenalty = double.tryParse(_heightPenalty.text) ?? 0.5;
    final refAltitude = double.tryParse(_referenceAltitude.text) ?? 200;
    final aboveRefPenalty = double.tryParse(_aboveRefPenalty.text) ?? 3.0;

    MotorRestartMode motorRestart;
    switch (_motorRestartMode) {
      case 'nonDroppableZero':
        motorRestart = MotorRestartMode.nonDroppableZero;
        break;
      case 'notAllowed':
        motorRestart = MotorRestartMode.notAllowed;
        break;
      default:
        motorRestart = MotorRestartMode.allowed;
    }

    final config = ContestScoringConfig(
      discipline: Discipline.f5j,
      targetTimeSeconds: targetTime,
      pointsPerSecond: pps,
      f5jWorkingTimeSeconds: targetTime.toInt(),
      f5jHeightPenaltyPerMeter: heightPenalty,
      f5jReferenceAltitudeMeters: refAltitude,
      f5jAboveReferencePenaltyPerMeter: aboveRefPenalty,
      f5jMotorRestart: motorRestart,
    );

    final flights = <F5JFlight>[];
    try {
      for (final pilot in pilots) {
        final duration = parseDuration(pilot['durationSeconds']);
        final altitude = double.tryParse(pilot['launchAltitudeMeters']);
        final landingBonus = int.tryParse(pilot['landingBonus']) ?? 0;

      ZeroReason? zeroReason;
      if (pilot['zeroReason'] == 'outOfBounds') {
        zeroReason = const OutOfBoundsLanding();
      } else if (pilot['zeroReason'] == 'overflight') {
        zeroReason = const OverFlightOverOneMinute();
      } else if (pilot['zeroReason'] == 'motorRestart') {
        zeroReason = const MotorRestart();
      }

      flights.add(F5JFlight(
        id: pilot['id'],
        pilotId: pilot['name'],
        durationSeconds: duration,
        launchAltitudeMeters: altitude,
        landingBonus: landingBonus,
        zeroReason: zeroReason,
      ));
    }
    } catch (e) {
      setState(() {
        _scoringError = 'Error parsing flight time: $e. Use formats like 600, 600.5, or 10:00';
        _scores = null;
      });
      return;
    }

    final engine = ScoringEngine();
    setState(() {
      try {
        _scores = engine.normalizeGroupScores(flights, config);
        _scoringError = null;
      } catch (e) {
        _scoringError = e.toString();
        _scores = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('F5J Scoring Test')),
      body: Column(children: [
        _buildConfigSection(),
        _buildPilotCountSection(),
        _buildPilotsSection(),
        if (_scoringError != null) _buildErrorSection(),
        if (_scores != null) _buildResultsSection(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pilots.isEmpty ? null : _runScoring,
        label: const Text('Run Scoring'),
        icon: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('F5J Contest Configuration',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _targetTimeSeconds,
            decoration: const InputDecoration(
              labelText: 'Working Time (seconds or M:ss)',
              hintText: 'e.g. 600 or 10:00',
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _pointsPerSecond,
            decoration: const InputDecoration(
              labelText: 'Points Per Second',
              hintText: 'e.g. 1.0',
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightPenalty,
            decoration: const InputDecoration(
              labelText: 'Height Penalty Per Meter',
              hintText: 'e.g. 0.5',
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _referenceAltitude,
            decoration: const InputDecoration(
              labelText: 'Reference Altitude (meters)',
              hintText: 'e.g. 200',
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _aboveRefPenalty,
            decoration: const InputDecoration(
              labelText: 'Above Reference Penalty Per Meter',
              hintText: 'e.g. 3.0',
            ),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            value: _motorRestartMode,
            decoration: const InputDecoration(
              labelText: 'Motor Restart Mode',
            ),
            items: const [
              DropdownMenuItem(value: 'allowed', child: Text('Allowed (droppable 0)')),
              DropdownMenuItem(value: 'nonDroppableZero', child: Text('Allowed (non-droppable 0)')),
              DropdownMenuItem(value: 'notAllowed', child: Text('Not Allowed')),
            ],
            onChanged: (value) {
              setState(() {
                _motorRestartMode = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPilotCountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _pilotCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Pilots',
                hintText: 'e.g. 3',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _addPilots, child: const Text('Add')),
        ],
      ),
    );
  }

  Widget _buildPilotsSection() {
    if (pilots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Add pilots to begin testing.'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: pilots.length,
        itemBuilder: (context, index) {
          final pilot = pilots[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilot ${index + 1} (${pilot["name"]})',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      hintText: 'e.g. 600 or 10:00',
                    ),
                    controller: TextEditingController(text: pilot['durationSeconds']),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      pilot['durationSeconds'] = v;
                    },
                  ),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Height (m)'),
                        controller: TextEditingController(text: pilot['launchAltitudeMeters']),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          pilot['launchAltitudeMeters'] = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Landing Bonus'),
                        controller: TextEditingController(text: pilot['landingBonus']),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          pilot['landingBonus'] = v;
                        },
                      ),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Normal'),
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Restart'),
                        selected: pilot['zeroReason'] == 'motorRestart',
                        onSelected: (s) {
                          setState(() {
                            pilot['zeroReason'] = 'motorRestart';
                          });
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red.shade100,
        child: Text(
          _scoringError!,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final scores = _scores!.scores;
    final sortedScores = scores.toList()..sort((a, b) => b.groupScore
        .compareTo(a.groupScore));

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scoring Results',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Card(child: _buildResultsTable(sortedScores)),
        ],
      ),
    );
  }

  Widget _buildResultsTable(List<ScoreResult> sortedScores) {
    return SingleChildScrollView(
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
    );
  }
}
