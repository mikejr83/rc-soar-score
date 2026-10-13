import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/participant_number_range.dart';

import '../../support/matrix_test_support.dart';

void main() {
  test('is null before any number is handed out', () {
    expect(ParticipantNumberRange.of(matrixParticipations()), isNull);
    expect(ParticipantNumberRange.of(const []), isNull);
  });

  test('spans the lowest and highest number', () {
    final range = ParticipantNumberRange.of(
      matrixParticipations(numbered: true),
    );
    expect(range?.lowest, 1);
    expect(range?.highest, 4);
  });
}
