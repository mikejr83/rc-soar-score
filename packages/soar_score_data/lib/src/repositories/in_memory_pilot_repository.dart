import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/src/repositories/pilot_repository.dart';

/// In-memory [PilotRepository].
///
/// Used as the default backing store for local, director-owned participant
/// records. A production deployment would swap this for a persistent
/// (e.g. SQLite) implementation of the same interface without changing the
/// UI.
class InMemoryPilotRepository extends PilotRepository {
  final Map<String, Pilot> _pilots = {};

  @override
  Future<List<Pilot>> getPilots() async {
    return _pilots.values.toList()
      ..sort((a, b) => _displayName(a).compareTo(_displayName(b)));
  }

  @override
  Future<Pilot?> getPilot(String id) async {
    return _pilots[id];
  }

  @override
  Future<void> savePilot(Pilot pilot) async {
    _pilots[pilot.id] = pilot;
  }

  /// Remove a pilot by [id]. Returns `true` if it existed.
  Future<bool> deletePilot(String id) async {
    return _pilots.remove(id) != null;
  }

  /// Clears all stored pilots.
  void clear() => _pilots.clear();

  static String _displayName(Pilot p) => '${p.lastName} ${p.firstName}';
}