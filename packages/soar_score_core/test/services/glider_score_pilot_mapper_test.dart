import 'dart:convert';
import 'dart:io';

import 'package:soar_score_core/import/glider_score_countries.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

GliderScoreImportResult _snapshot(String file) {
  final json = jsonDecode(
    File('test/fixtures/gliderscore/$file').readAsStringSync(),
  ) as Map<String, Object?>;
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: json['sourceDbFile']! as String,
    tables: [
      for (final t
          in (json['tables']! as List<Object?>).cast<Map<String, Object?>>())
        GliderScoreTable(
          name: t['name']! as String,
          rows: (t['rows']! as List<Object?>).cast<Map<String, Object?>>(),
          rowCount: t['rowCount']! as int,
          rowCapExceeded: t['rowCapExceeded']! as bool,
        ),
    ],
  );
}

GliderScoreImportResult _rows(
  List<Map<String, Object?>> rows, {
  String name = 'Pilots',
  bool capped = false,
}) => GliderScoreImportResult(
  id: Id.create(),
  sourceDbFile: 'x.mdb',
  tables: [
    GliderScoreTable(
      name: name,
      rows: rows,
      rowCount: rows.length + (capped ? 5 : 0),
      rowCapExceeded: capped,
    ),
  ],
);

PilotDraft _byNo(PilotImportDraft draft, int no) =>
    draft.pilots.singleWhere((p) => p.sourcePilotNo == no);

Set<String> _codes(PilotDraft p) => {for (final w in p.warnings) w.code};

void main() {
  const mapper = GliderScorePilotMapper();

  group('reference file', () {
    final draft = mapper.map(_snapshot('pilots_reference.json'));

    test('excludes the ZZ test users and keeps everyone else', () {
      expect(draft.excludedTestUsers, 74);
      expect(draft.pilots, hasLength(84));
      expect(draft.skipped, isEmpty);
      expect(
        draft.pilots.any((p) => p.lastName.toUpperCase().startsWith('ZZ')),
        isFalse,
      );
    });

    test('carries email and state, and drops placeholder numbers', () {
      expect(draft.pilots.where((p) => p.email != null), isNotEmpty);
      expect(draft.pilots.where((p) => p.state != null), isNotEmpty);
      expect(draft.pilots.every((p) => p.faiNumber == null), isTrue);
      expect(draft.pilots.every((p) => p.nationalOrgId == null), isTrue);
    });

    test('converts country codes to names; blanks are warned', () {
      final countries = {for (final p in draft.pilots) p.country};
      expect(countries, containsAll(['United States', 'Canada']));
      expect(
        draft.pilots
            .where((p) => p.country == null)
            .every(
              (p) => _codes(p).contains(PilotImportWarning.countryMissing),
            ),
        isTrue,
      );
    });
  });

  group('edge cases', () {
    final draft = mapper.map(_snapshot('pilots_edge_cases.json'));

    test('keeps same-name pilots as separate drafts', () {
      expect(_byNo(draft, 1001).lastName, 'Twin');
      expect(_byNo(draft, 1002).lastName, 'Twin');
    });

    test('keeps real FAI and registration numbers', () {
      final p = _byNo(draft, 1005);
      expect(p.faiNumber, 'FAI12345');
      expect(p.nationalOrgId, 'NAT-0042');
      expect(_codes(p), isNot(contains(PilotImportWarning.faiIdDiffers)));
    });

    test('warns when FAI_ID differs and FAINumber wins', () {
      final p = _byNo(draft, 1006);
      expect(p.faiNumber, 'FAI777');
      expect(_codes(p), contains(PilotImportWarning.faiIdDiffers));
    });

    test('turns blanks and placeholders into null', () {
      final p = _byNo(draft, 1007);
      expect(p.email, isNull);
      expect(p.faiNumber, isNull);
      expect(p.nationalOrgId, isNull);
      expect(p.state, isNull);
      expect(p.country, isNull);
    });

    test('excludes ZZ in any case or padding, not a name containing zz', () {
      expect(draft.pilots.map((p) => p.sourcePilotNo), isNot(contains(1008)));
      expect(draft.pilots.map((p) => p.sourcePilotNo), isNot(contains(1009)));
      expect(draft.pilots.map((p) => p.sourcePilotNo), contains(1010));
      expect(draft.excludedTestUsers, 2);
    });

    test('skips pilots without both names', () {
      expect(
        draft.skipped.map((s) => s.sourcePilotNo),
        unorderedEquals([1011, 1012, 1013]),
      );
      expect(
        draft.skipped.every((s) => s.reason == PilotImportWarning.missingName),
        isTrue,
      );
    });

    test('maps IOC codes, warns about unknown ones, accepts known names', () {
      expect(_byNo(draft, 1014).country, 'Germany');
      expect(_byNo(draft, 1015).country, isNull);
      expect(
        _codes(_byNo(draft, 1015)),
        contains(PilotImportWarning.countryUnknown),
      );
      expect(_byNo(draft, 1016).country, 'United States');
    });

    test('trims text and maps club, town and state', () {
      final p = _byNo(draft, 1017);
      expect(p.firstName, 'Zoë');
      expect(p.lastName, 'Accent');
      expect(p.club, 'Example Soaring Club');
      expect(p.city, 'Exampleton');
      expect(p.state, 'ZZ');
    });

    test('counts the columns that have no profile field', () {
      expect(draft.droppedFieldCounts['Street'], 1);
      expect(draft.droppedFieldCounts['PostCode'], 1);
      expect(draft.droppedFieldCounts['UsualModel'], 1);
      expect(draft.droppedFieldCounts['UsualClass'], 1);
    });
  });

  group('robustness', () {
    test('old column set maps with no newer columns', () {
      final draft = mapper.map(_snapshot('pilots_old_columns.json'));
      expect(draft.pilots, isNotEmpty);
      expect(draft.pilots.every((p) => p.email == null), isTrue);
    });

    test('unknown extra columns are ignored', () {
      final draft = mapper.map(_snapshot('pilots_extra_columns.json'));
      expect(draft.pilots, hasLength(5));
    });

    test('a missing Pilots table is a warning, not an error', () {
      final draft = mapper.map(_rows(const [], name: 'Comps'));
      expect(draft.pilots, isEmpty);
      expect(draft.warnings.single.code, PilotImportWarning.pilotsTableMissing);
    });

    test('table name match ignores case', () {
      final draft = mapper.map(
        _rows(const [
          {'PilotNo': 1, 'FirstName': 'A', 'LastName': 'B'},
        ], name: 'PILOTS'),
      );
      expect(draft.pilots, hasLength(1));
    });

    test('a truncated table is flagged', () {
      final draft = mapper.map(
        _rows(const [
          {'PilotNo': 1, 'FirstName': 'A', 'LastName': 'B'},
        ], capped: true),
      );
      expect(draft.warnings.single.code, PilotImportWarning.rowsTruncated);
    });

    test('duplicate pilot numbers skip the later row', () {
      final draft = mapper.map(
        _rows(const [
          {'PilotNo': 7, 'FirstName': 'A', 'LastName': 'B'},
          {'PilotNo': 7, 'FirstName': 'C', 'LastName': 'D'},
        ]),
      );
      expect(draft.pilots.single.firstName, 'A');
      expect(
        draft.skipped.single.reason,
        PilotImportWarning.duplicatePilotNumber,
      );
    });

    test('odd value types do not throw', () {
      final draft = mapper.map(
        _rows(const [
          {'PilotNo': '12', 'FirstName': 5, 'LastName': true, 'Email': 'nope'},
          {'PilotNo': 13, 'FirstName': 'Ok', 'LastName': 'Pilot', 'Email': 3},
        ]),
      );
      expect(draft.pilots, hasLength(2));
      expect(draft.pilots.first.sourcePilotNo, 12);
      expect(
        _codes(draft.pilots.first),
        contains(PilotImportWarning.emailInvalid),
      );
    });

    test('a row without a usable PilotNo is skipped with a code', () {
      final draft = mapper.map(
        _rows(const [
          {'FirstName': 'No', 'LastName': 'Number'},
          {'PilotNo': 'abc', 'FirstName': 'Bad', 'LastName': 'Number'},
          {'PilotNo': null, 'FirstName': 'Null', 'LastName': 'Number'},
          {'PilotNo': 5, 'FirstName': 'Good', 'LastName': 'Number'},
        ]),
      );
      expect(draft.pilots.single.sourcePilotNo, 5);
      expect(draft.skipped, hasLength(3));
      expect(
        draft.skipped.every(
          (s) => s.reason == PilotImportWarning.missingNumber,
        ),
        isTrue,
      );
    });

    test('malformed emails are dropped with a warning', () {
      for (final bad in ['a@', '@x.test', 'a b@x.test', 'a@x', 'a@@x.test']) {
        final draft = mapper.map(
          _rows([
            {'PilotNo': 1, 'FirstName': 'A', 'LastName': 'B', 'Email': bad},
          ]),
        );
        expect(draft.pilots.single.email, isNull, reason: bad);
        expect(
          _codes(draft.pilots.single),
          contains(PilotImportWarning.emailInvalid),
          reason: bad,
        );
      }
      final ok = mapper.map(
        _rows(const [
          {
            'PilotNo': 1,
            'FirstName': 'A',
            'LastName': 'B',
            'Email': ' a@x.test ',
          },
        ]),
      );
      expect(ok.pilots.single.email, 'a@x.test');
    });

    test('FAI_ID is used when FAINumber is a placeholder', () {
      final draft = mapper.map(
        _rows(const [
          {
            'PilotNo': 1,
            'FirstName': 'A',
            'LastName': 'B',
            'FAINumber': '0',
            'FAI_ID': 'FAI9',
          },
        ]),
      );
      expect(draft.pilots.single.faiNumber, 'FAI9');
    });
  });

  group('country table', () {
    test('every code in GliderScore resolves to a non-empty name', () {
      expect(gliderScoreCountryNames, hasLength(206));
      expect(gliderScoreCountryNames.values.every((n) => n.isNotEmpty), isTrue);
    });

    test('uses the contest app spelling for the US and UK', () {
      expect(gliderScoreCountryNames['USA'], 'United States');
      expect(gliderScoreCountryNames['GBR'], 'United Kingdom');
      expect(gliderScoreCountryNames['NZL'], 'New Zealand');
    });
  });
}
