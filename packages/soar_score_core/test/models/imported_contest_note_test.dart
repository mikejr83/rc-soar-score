import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

final _contestId = Id.create();

ImportProvenance _stamp(String type, {Map<String, Object?>? values}) =>
    ImportProvenance(
      id: Id.create(),
      ownerAccountId: Id.create(),
      contestId: _contestId,
      stampedEntityType: type,
      stampedEntityId: type == ImportProvenance.contestEntityType
          ? _contestId
          : Id.create(),
      sourceSystem: ImportProvenance.gliderScore,
      sourceKeys: type == ImportProvenance.matrixRevisionEntityType
          ? {'comp_no': 1, 'task_no': 1}
          : {'comp_no': 1},
      sourceValues: values,
      fileFingerprint: 'sha256:x',
      importOperationId: Id.create(),
      toolVersion: '1',
      importedAt: DateTime.utc(2026, 11, 4),
    );

void main() {
  test('a contest without stamps has no note', () {
    expect(ImportedContestNote.fromStamps([]), isNull);
  });

  test('a contest stamp alone means no draw was imported', () {
    final note = ImportedContestNote.fromStamps([
      _stamp(ImportProvenance.contestEntityType),
    ])!;
    expect(note.drawImported, isFalse);
    expect(note.importedAt, DateTime.utc(2026, 11, 4));
  });

  test('a revision stamp means the draw came from GliderScore', () {
    final note = ImportedContestNote.fromStamps([
      _stamp(ImportProvenance.contestEntityType),
      _stamp(ImportProvenance.matrixRevisionEntityType, values: {}),
    ])!;
    expect(note.drawImported, isTrue);
    expect(note.lanesKept, isTrue);
  });

  test('positions in a revision stamp mean the draw has no lanes', () {
    final note = ImportedContestNote.fromStamps([
      _stamp(ImportProvenance.contestEntityType),
      _stamp(
        ImportProvenance.matrixRevisionEntityType,
        values: {'positions': <Object?>[]},
      ),
    ])!;
    expect(note.lanesKept, isFalse);
  });
}
