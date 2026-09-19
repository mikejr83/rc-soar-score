import 'package:soar_score_core/soar_score_core.dart';

/// Repository interface for pilot data.
abstract class PilotRepository {
  Future<List<Pilot>> getPilots();
  Future<void> savePilot(Pilot pilot);

  /// Returns the pilot with the given [id], or `null` if none exists.
  Future<Pilot?> getPilot(String id);

  /// Remove a pilot by [id]. Returns `true` if it existed.
  Future<bool> deletePilot(String id);
}