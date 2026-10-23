import 'landing_result.dart';

/// Placeholder content until the self-scoring API exists. The pages read
/// these constants so the layout can be reviewed on real-looking data.
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
}
