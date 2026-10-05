import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

ConfigChange change(Map<String, Object?> before, Map<String, Object?> after) =>
    classifyConfigChange(
      beforeCore: before,
      afterCore: after,
      beforeDiscipline: const {},
      afterDiscipline: const {},
      state: LifecycleState.configuring,
    );

void main() {
  test('a recalculating config change recomputes everything', () {
    final scope = RecalculationScope.forConfigChange(
      change({'decimal_places': 1}, {'decimal_places': 2}),
    );
    expect(scope!.fromRound, 1);
    expect(scope.isFull, isTrue);
    expect(scope.reason, RecalculationReason.configChange);
  });

  test('a presentation change needs no recalculation', () {
    expect(
      RecalculationScope.forConfigChange(
        change({'classes_enabled': false}, {'classes_enabled': true}),
      ),
      isNull,
    );
  });

  test('a score change recomputes from its round', () {
    final scope = RecalculationScope.forScoreChange(5);
    expect(scope.fromRound, 5);
    expect(scope.isFull, isFalse);
  });

  test('a matrix change recomputes from the earliest affected round', () {
    expect(RecalculationScope.forMatrixChange(3).fromRound, 3);
    expect(
      RecalculationScope.forMatrixChange(3).reason,
      RecalculationReason.matrixChange,
    );
  });

  test('a calculation version change recomputes everything', () {
    expect(
      RecalculationScope.forCalculationVersion(
        storedVersion: 'f5j-1',
        currentVersion: 'f5j-1',
      ),
      isNull,
    );
    expect(
      RecalculationScope.forCalculationVersion(
        storedVersion: 'f5j-1',
        currentVersion: 'f5j-2',
      )!.isFull,
      isTrue,
    );
  });

  test('rounds start at 1', () {
    expect(() => RecalculationScope.forScoreChange(0), throwsArgumentError);
    expect(() => RecalculationScope.forMatrixChange(0), throwsArgumentError);
  });
}
