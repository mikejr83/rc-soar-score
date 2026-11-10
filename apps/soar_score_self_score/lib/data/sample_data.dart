import '../models/group_result_row.dart';
import '../models/landing_result.dart';
import '../models/pilot_round.dart';
import '../models/results_snapshot.dart';

/// Placeholder content until the self-scoring API exists. Only
/// `SampleSelfScoreRepository` reads it; pages go through the repository.
abstract final class SampleData {
  static const contestId = 'spring-open';
  static const contestName = 'Spring Open';
  static const pilotName = 'Jane Smith';
  static const teamName = 'Team Kestrel';

  /// An F5J-sized landing table: well under the sheet threshold.
  static const landingTable = [
    LandingResult(
      id: 'inside',
      label: 'Inside',
      points: 100,
      description: 'Within 10 m of the marker',
    ),
    LandingResult(
      id: 'near',
      label: 'Near',
      points: 80,
      description: '10 to 25 m',
    ),
    LandingResult(
      id: 'good',
      label: 'Good',
      points: 50,
      description: '25 to 50 m',
    ),
    LandingResult(
      id: 'far',
      label: 'Far',
      points: 20,
      description: '50 to 75 m',
    ),
  ];

  static const latestRound = 4;
  static const heldRound = 4;

  static const pilotNames = {
    '12': 'Jane Smith',
    '7': 'Tom Reid',
    '3': 'Ana Lopez',
    '21': 'Sam Park',
    '15': 'Li Wei',
    '9': 'Kate Brooks',
  };

  static String pilotNameOf(String pilotId) =>
      pilotNames[pilotId] ?? 'Pilot $pilotId';

  static const pilotRounds = [
    PilotRound(
      number: 1,
      group: 'A',
      lane: 3,
      status: PilotRoundStatus.submitted,
      enteredBy: 'you',
    ),
    PilotRound(
      number: 2,
      group: 'C',
      lane: 1,
      status: PilotRoundStatus.submitted,
      enteredBy: 'Tom Reid',
    ),
    PilotRound(
      number: 3,
      group: 'A',
      lane: 2,
      status: PilotRoundStatus.pendingReview,
      enteredBy: 'you',
    ),
    PilotRound(
      number: 4,
      group: 'B',
      lane: 1,
      status: PilotRoundStatus.nextToScore,
    ),
    PilotRound(
      number: 5,
      group: 'D',
      lane: 4,
      status: PilotRoundStatus.upcoming,
    ),
    PilotRound(
      number: 6,
      group: 'A',
      lane: 1,
      status: PilotRoundStatus.upcoming,
    ),
    PilotRound(
      number: 7,
      group: 'C',
      lane: 2,
      status: PilotRoundStatus.upcoming,
    ),
    PilotRound(
      number: 8,
      group: 'B',
      lane: 3,
      status: PilotRoundStatus.upcoming,
    ),
  ];

  static const groupBResults = [
    GroupResultRow(
      name: 'Li Wei',
      pilotNumber: 15,
      kind: GroupRowKind.scored,
      time: '7:12.0',
      height: 60,
      landing: 'Inside',
      rawScore: '912',
      score: '912',
    ),
    GroupResultRow(
      name: 'Tom Reid',
      pilotNumber: 7,
      kind: GroupRowKind.scored,
      time: '6:58.2',
      height: 50,
      landing: 'Good',
      rawScore: '884',
      score: '884',
    ),
    GroupResultRow(
      name: 'Jane Smith',
      pilotNumber: 12,
      kind: GroupRowKind.scored,
      time: '6:30.4',
      height: 45,
      landing: 'Good',
      rawScore: '863',
      score: '863',
      isYou: true,
    ),
    GroupResultRow(
      name: 'Ana Lopez',
      pilotNumber: 3,
      kind: GroupRowKind.zero,
      zeroReason: 'out of bounds',
      time: '0:00.0',
      score: '0',
    ),
    GroupResultRow(
      name: 'Kate Brooks',
      pilotNumber: 9,
      kind: GroupRowKind.noScore,
    ),
    GroupResultRow(
      name: 'Sam Park',
      pilotNumber: 21,
      kind: GroupRowKind.pendingReview,
      time: '6:02.0',
      height: 50,
      landing: 'Good',
      rawScore: '860',
      score: '860',
    ),
  ];

  static const teamStandings = [
    StandingLine(place: '1', name: 'Team Osprey', score: '412'),
    StandingLine(place: '2', name: teamName, score: '398', isYou: true),
    StandingLine(place: '3', name: 'Team Merlin', score: '371'),
  ];

  static const results = {
    4: ResultsSnapshot(
      round: 4,
      ordinal: '3rd',
      score: '2,184',
      teams: teamStandings,
      pilots: [
        StandingLine(place: '1', name: 'Li Wei', score: '2,231'),
        StandingLine(place: '2', name: 'Tom Reid', score: '2,207'),
        StandingLine(place: '3', name: pilotName, score: '2,184', isYou: true),
        StandingLine(
          place: '3=',
          name: 'Ana Lopez',
          score: '2,184',
          tied: true,
        ),
        StandingLine(place: '5', name: 'Kate Brooks', score: '2,096'),
      ],
    ),
    3: ResultsSnapshot(
      round: 3,
      ordinal: '4th',
      score: '1,702',
      teams: teamStandings,
      pilots: [
        StandingLine(place: '1', name: 'Tom Reid', score: '1,788'),
        StandingLine(place: '2', name: 'Li Wei', score: '1,745'),
        StandingLine(place: '3', name: 'Ana Lopez', score: '1,719'),
        StandingLine(place: '4', name: pilotName, score: '1,702', isYou: true),
        StandingLine(place: '5', name: 'Kate Brooks', score: '1,650'),
      ],
    ),
  };
}
