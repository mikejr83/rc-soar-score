import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/services/flight_time_input.dart';

void main() {
  test('reads compact minutes and seconds', () {
    expect(FlightTimeInput.parse('630').seconds, 390);
    expect(FlightTimeInput.parse('630.4').seconds, 390.4);
    expect(FlightTimeInput.parse('45').seconds, 45);
  });

  test('rejects seconds over 59 and non-numeric text', () {
    expect(FlightTimeInput.parse('675').isValid, false);
    expect(FlightTimeInput.parse('675').error, isNotNull);
    expect(FlightTimeInput.parse('6:30').error, isNotNull);
  });

  test('empty input is neither valid nor an error', () {
    final input = FlightTimeInput.parse(' ');
    expect(input.isValid, false);
    expect(input.error, isNull);
  });

  test('formats as m:ss with optional tenths', () {
    expect(FlightTimeInput.format(390), '6:30');
    expect(FlightTimeInput.format(390.4), '6:30.4');
  });
}
