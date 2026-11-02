import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The brand fonts bundled by this package and the licence file for each.
const _brandFontLicenses = <(String, String)>[
  ('Archivo', 'assets/fonts/archivo/OFL.txt'),
  ('League Spartan', 'assets/fonts/league_spartan/OFL.txt'),
  ('Saira Stencil One', 'assets/fonts/saira_stencil_one/OFL.txt'),
];

bool _registered = false;

/// Adds the licences of the bundled brand fonts to Flutter's
/// `LicenseRegistry`, so `showLicensePage` lists them with the packages.
///
/// Call once at start-up. Calling again does nothing.
void registerBrandFontLicenses({AssetBundle? bundle}) {
  if (_registered) return;
  _registered = true;
  final source = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final (name, asset) in _brandFontLicenses) {
      final text = await source.loadString('packages/soar_score_ui/$asset');
      yield LicenseEntryWithLineBreaks(['$name (font)'], text);
    }
  });
}
