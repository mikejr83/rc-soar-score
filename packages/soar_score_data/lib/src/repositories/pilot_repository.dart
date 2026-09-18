import 'package:soar_score_core/soar_score_core.dart';

/// Repository interface for pilot data.
abstract class PilotRepository {
  Future<List<Pilot>> getPilots();
  Future<void> savePilot(Pilot pilot);
}