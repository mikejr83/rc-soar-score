import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final config = Id.create();
  final matrix = Id.create();
  final stamps = ResultStamps(
    configRevisionId: config,
    matrixRevisionId: matrix,
    calculationVersion: f5jCalculationVersion,
  );

  test('identical stamps are current', () {
    expect(stamps.isStale(stamps), isFalse);
  });

  test('a new config revision, matrix revision or version is stale', () {
    expect(
      stamps.isStale(
        ResultStamps(
          configRevisionId: Id.create(),
          matrixRevisionId: matrix,
          calculationVersion: f5jCalculationVersion,
        ),
      ),
      isTrue,
    );
    expect(
      stamps.isStale(
        ResultStamps(
          configRevisionId: config,
          matrixRevisionId: Id.create(),
          calculationVersion: f5jCalculationVersion,
        ),
      ),
      isTrue,
    );
    expect(
      stamps.isStale(
        ResultStamps(
          configRevisionId: config,
          matrixRevisionId: matrix,
          calculationVersion: 'f5j-2',
        ),
      ),
      isTrue,
    );
  });
}
