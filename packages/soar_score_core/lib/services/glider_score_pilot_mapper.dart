import '../import/glider_score_countries.dart';
import '../models/imports/glider_score_import_result.dart';
import '../models/imports/pilot_import_draft.dart';

/// Turns the `Pilots` table of a [GliderScoreImportResult] into a
/// [PilotImportDraft] for the director to review.
///
/// Pure: no I/O, never throws on odd input. Every column except the pilot
/// number and the names is optional, because GliderScore versions differ and
/// the exporter leaves null columns out of a row altogether.
class GliderScorePilotMapper {
  const GliderScorePilotMapper();

  /// GliderScore columns with no `ParticipantProfile` field.
  static const droppedColumns = <String>[
    'Street',
    'PostCode',
    'PrivatePhone',
    'WorkPhone',
    'UsualClass',
    'UsualModel',
  ];

  PilotImportDraft map(GliderScoreImportResult result) {
    final table = _pilotsTable(result);
    if (table == null) {
      return const PilotImportDraft(
        pilots: [],
        skipped: [],
        excludedTestUsers: 0,
        droppedFieldCounts: {},
        warnings: [PilotImportWarning(PilotImportWarning.pilotsTableMissing)],
      );
    }

    final warnings = <PilotImportWarning>[
      if (table.rowCapExceeded)
        PilotImportWarning(
          PilotImportWarning.rowsTruncated,
          detail: '${table.rows.length} of ${table.rowCount}',
        ),
    ];
    final pilots = <PilotDraft>[];
    final skipped = <SkippedPilot>[];
    final dropped = <String, int>{};
    final seenNumbers = <int>{};
    var excluded = 0;

    for (final row in table.rows) {
      final no = _int(row['PilotNo']);
      final first = _text(row['FirstName']);
      final last = _text(row['LastName']);

      if (first == null || last == null) {
        skipped.add(
          SkippedPilot(
            sourcePilotNo: no,
            reason: PilotImportWarning.missingName,
          ),
        );
        continue;
      }
      if (last.toUpperCase().startsWith('ZZ')) {
        excluded++;
        continue;
      }
      if (no != null && !seenNumbers.add(no)) {
        skipped.add(
          SkippedPilot(
            sourcePilotNo: no,
            reason: PilotImportWarning.duplicatePilotNumber,
          ),
        );
        continue;
      }

      final pilotWarnings = <PilotImportWarning>[];

      String? email = _text(row['Email']);
      if (email != null && !email.contains('@')) {
        pilotWarnings.add(
          PilotImportWarning(
            PilotImportWarning.emailInvalid,
            sourcePilotNo: no,
            detail: email,
          ),
        );
        email = null;
      }

      final faiNumber = _registration(row['FAINumber']);
      final faiId = _registration(row['FAI_ID']);
      if (faiNumber != null && faiId != null && faiNumber != faiId) {
        pilotWarnings.add(
          PilotImportWarning(
            PilotImportWarning.faiIdDiffers,
            sourcePilotNo: no,
            detail: faiId,
          ),
        );
      }

      final rawCountry = _text(row['Country']);
      String? country;
      if (rawCountry == null) {
        pilotWarnings.add(
          PilotImportWarning(
            PilotImportWarning.countryMissing,
            sourcePilotNo: no,
          ),
        );
      } else {
        country = _country(rawCountry);
        if (country == null) {
          pilotWarnings.add(
            PilotImportWarning(
              PilotImportWarning.countryUnknown,
              sourcePilotNo: no,
              detail: rawCountry,
            ),
          );
        }
      }

      for (final column in droppedColumns) {
        if (_text(row[column]) != null) {
          dropped[column] = (dropped[column] ?? 0) + 1;
        }
      }

      pilots.add(
        PilotDraft(
          sourcePilotNo: no,
          firstName: first,
          lastName: last,
          email: email,
          faiNumber: faiNumber ?? faiId,
          nationalOrgId: _registration(row['OtherRegistration']),
          club: _text(row['Club']),
          city: _text(row['Town']),
          state: _text(row['State']),
          country: country,
          warnings: pilotWarnings,
        ),
      );
    }

    return PilotImportDraft(
      pilots: pilots,
      skipped: skipped,
      excludedTestUsers: excluded,
      droppedFieldCounts: dropped,
      warnings: warnings,
    );
  }

  static GliderScoreTable? _pilotsTable(GliderScoreImportResult result) {
    for (final table in result.tables) {
      if (table.name.toLowerCase() == 'pilots') {
        return table;
      }
    }
    return null;
  }

  /// [value] trimmed, or null when it is not text or is blank.
  static String? _text(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// A FAI or registration number; GliderScore writes `0` for none.
  static String? _registration(Object? value) {
    final text = _text(value);
    if (text == null || RegExp(r'^0+$').hasMatch(text)) {
      return null;
    }
    return text;
  }

  static int? _int(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return value is String ? int.tryParse(value.trim()) : null;
  }

  /// The English name for a GliderScore code, or [text] when it already is a
  /// known name; null when it is neither.
  static String? _country(String text) {
    final byCode = gliderScoreCountryNames[text.toUpperCase()];
    if (byCode != null) {
      return byCode;
    }
    final lower = text.toLowerCase();
    for (final name in gliderScoreCountryNames.values) {
      if (name.toLowerCase() == lower) {
        return name;
      }
    }
    return null;
  }
}
