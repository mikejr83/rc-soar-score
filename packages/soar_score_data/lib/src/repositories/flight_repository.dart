import 'package:soar_score_core/soar_score_core.dart';

/// Repository interface for flight data.
abstract class FlightRepository {
  Future<List<Flight>> getFlights();
  Future<void> saveFlight(Flight flight);
}