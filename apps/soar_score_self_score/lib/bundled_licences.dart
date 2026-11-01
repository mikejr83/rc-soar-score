import 'package:flutter/foundation.dart';

/// Adds the project's own licence notice to Flutter's `LicenseRegistry`, so
/// the in-app licence list names the AGPL-3.0 and the source code location.
///
/// Dart and Flutter packages register themselves, and the brand fonts are
/// registered by `registerBrandFontLicenses` in `soar_score_ui`.
void registerProjectLicence() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['RC Soar Score'],
      'RC Soar Score is free software under the GNU Affero General Public '
      'License, version 3 (AGPL-3.0). Source code: '
      'https://github.com/mikejr83/rc-soar-score',
    );
  });
}
