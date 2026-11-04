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
  preferredTests();
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

const _lowId = '01900000-0000-7000-8000-000000000001';
const _highId = '01900000-0000-7000-8000-000000000002';

ImportProvenance _contestStamp({
  required String id,
  required String fingerprint,
  required DateTime at,
}) {
  final contest = Id.create();
  return ImportProvenance(
    id: Id.parse(id),
    ownerAccountId: Id.create(),
    contestId: contest,
    stampedEntityType: ImportProvenance.contestEntityType,
    stampedEntityId: contest,
    sourceSystem: ImportProvenance.gliderScore,
    sourceKeys: {'comp_no': 1},
    fileFingerprint: fingerprint,
    importOperationId: Id.create(),
    toolVersion: '1',
    importedAt: at,
  );
}

void preferredTests() {
  group('ImportProvenance.preferred', () {
    final t = DateTime.utc(2026, 11, 4);
    test('is null without candidates', () {
      expect(ImportProvenance.preferred([], 'a'), isNull);
    });

    test('the same file wins over a newer import', () {
      final same = _contestStamp(id: _lowId, fingerprint: 'f1', at: t);
      final newer = _contestStamp(
        id: _highId,
        fingerprint: 'f2',
        at: t.add(const Duration(days: 1)),
      );
      expect(ImportProvenance.preferred([newer, same], 'f1'), same);
    });

    test('otherwise the newest wins, whatever the order given', () {
      final old = _contestStamp(id: _lowId, fingerprint: 'f1', at: t);
      final fresh = _contestStamp(
        id: _highId,
        fingerprint: 'f2',
        at: t.add(const Duration(days: 1)),
      );
      expect(ImportProvenance.preferred([old, fresh], 'x'), fresh);
      expect(ImportProvenance.preferred([fresh, old], 'x'), fresh);
    });

    test('equal times choose the greater id every time', () {
      final low = _contestStamp(id: _lowId, fingerprint: 'f1', at: t);
      final high = _contestStamp(id: _highId, fingerprint: 'f2', at: t);
      expect(ImportProvenance.preferred([low, high], 'x'), high);
      expect(ImportProvenance.preferred([high, low], 'x'), high);
    });
  });
}
