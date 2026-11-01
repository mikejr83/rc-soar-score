import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The asset written by `scripts/generate_licences.dart --product contest-app
/// --json`; the same data feeds the public /open-source page and the
/// `THIRD_PARTY_NOTICES.txt` in the alpha zip.
const bundledLicencesAsset = 'assets/licences/contest-app.json';

/// Adds the licences of code that Flutter does not find on its own: native
/// libraries and helper programs in the Windows build, fonts, and the SDKs.
/// Dart and Flutter packages register themselves, so only the generator's
/// `bundled` entries are added. Works with no network.
///
/// [load] returns the JSON text; tests replace it.
void registerBundledLicences({Future<String> Function()? load}) {
  final read = load ?? () => rootBundle.loadString(bundledLicencesAsset);
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['RC Soar Score'],
      'RC Soar Score is free software under the GNU Affero General Public '
      'License, version 3 (AGPL-3.0). Source code: '
      'https://github.com/mikejr83/rc-soar-score',
    );
    final String json;
    try {
      json = await read();
    } on Object {
      return;
    }
    for (final entry in bundledLicenceEntries(json)) {
      yield entry;
    }
  });
}

/// The `bundled` entries of the generator's JSON, one licence entry per
/// licence text.
Iterable<LicenseEntry> bundledLicenceEntries(String json) sync* {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final texts = (data['texts'] as List).cast<String>();
  for (final product in (data['products'] as List).cast<Map>()) {
    for (final entry in (product['entries'] as List).cast<Map>()) {
      if (entry['source'] != 'bundled') {
        continue;
      }
      final name = entry['name'] as String;
      final licence = entry['license'] as String?;
      final note = entry['note'] as String?;
      final header = [
        if (licence != null && licence.isNotEmpty) 'Licence: $licence',
        if (note != null && note.isNotEmpty) note,
      ].join('\n\n');
      for (final index in (entry['texts'] as List).cast<int>()) {
        yield LicenseEntryWithLineBreaks([
          name,
        ], header.isEmpty ? texts[index] : '$header\n\n${texts[index]}');
      }
    }
  }
}
