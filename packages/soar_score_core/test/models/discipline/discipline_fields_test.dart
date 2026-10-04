import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

DisciplineConfigField config({
  ConfigFieldType type = ConfigFieldType.int,
  List<Object?>? options,
}) => DisciplineConfigField(
  id: exampleId(1),
  disciplineProfileId: exampleId(2),
  fieldKey: 'target_time',
  fieldType: type,
  name: 'Target time',
  options: options,
  createdAt: t0,
);

DisciplineScoreField score({
  ScoreFieldType type = ScoreFieldType.float,
  List<Object?>? options,
  bool isZeroReason = false,
  String? zeroReasonCode,
  int? precision,
}) => DisciplineScoreField(
  id: exampleId(3),
  disciplineProfileId: exampleId(2),
  fieldKey: 'flight_time',
  fieldType: type,
  name: 'Flight time',
  options: options,
  isZeroReason: isZeroReason,
  zeroReasonCode: zeroReasonCode,
  precision: precision,
  createdAt: t0,
);

void main() {
  group('DisciplineConfigField', () {
    test('round trips and is system scoped', () {
      final field = config();
      expect(DisciplineConfigField.fromJson(field.toJson()), field);
      expect(field.syncScope, SyncScope.system);
      expect(field.displayOrder, 0);
      expect(field.required, isFalse);
    });

    test('enum type serializes as "enum"', () {
      final field = config(type: ConfigFieldType.enumeration, options: ['a']);
      expect(field.toJson()['field_type'], 'enum');
    });

    test('options only belong to enum fields', () {
      expect(() => config(options: ['a']), throwsArgumentError);
    });
  });

  group('DisciplineScoreField', () {
    test('round trips with kind text', () {
      final field = score();
      final json = field.toJson();
      expect(json['field_kind'], 'input');
      expect(DisciplineScoreField.fromJson(json), field);
      expect(field.syncScope, SyncScope.system);
    });

    test('status flags serialize as "status_flag"', () {
      final json = score().toJson()..['field_kind'] = 'status_flag';
      expect(
        DisciplineScoreField.fromJson(json).fieldKind,
        ScoreFieldKind.statusFlag,
      );
    });

    test('options only belong to enum fields', () {
      expect(() => score(options: ['a']), throwsArgumentError);
    });

    test('a zero-reason field needs a code', () {
      expect(() => score(isZeroReason: true), throwsArgumentError);
      expect(
        score(isZeroReason: true, zeroReasonCode: 'OOB').isZeroReason,
        true,
      );
    });

    test('precision cannot be negative', () {
      expect(() => score(precision: -1), throwsArgumentError);
    });
  });
}
