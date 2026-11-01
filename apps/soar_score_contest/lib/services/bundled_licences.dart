import 'package:flutter/foundation.dart';

/// Adds the licences of code that ships in the Windows build but that
/// Flutter does not find on its own (native libraries linked by plugins), so
/// the in-app licence page can show them with no network.
///
/// Dart and Flutter packages register themselves. The full texts also ship
/// in `THIRD_PARTY_NOTICES.txt` in the alpha zip.
void registerBundledLicences() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['OpenSSL'],
      'Licensed under the Apache License, Version 2.0 '
      '(https://www.apache.org/licenses/LICENSE-2.0).\n\n'
      'Linked into the Windows app by the sign-in plugin.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['cpp-httplib', 'nlohmann/json'],
      'Licensed under the MIT License.\n\n'
      'Copyright (c) the cpp-httplib and nlohmann/json authors.\n\n'
      'Permission is hereby granted, free of charge, to any person obtaining '
      'a copy of this software and associated documentation files (the '
      '"Software"), to deal in the Software without restriction, including '
      'without limitation the rights to use, copy, modify, merge, publish, '
      'distribute, sublicense, and/or sell copies of the Software, and to '
      'permit persons to whom the Software is furnished to do so, subject to '
      'the following conditions:\n\n'
      'The above copyright notice and this permission notice shall be '
      'included in all copies or substantial portions of the Software.\n\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, '
      'EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF '
      'MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND '
      'NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS '
      'BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN '
      'ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN '
      'CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
      'SOFTWARE.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['RC Soar Score'],
      'RC Soar Score is free software under the GNU Affero General Public '
      'License, version 3 (AGPL-3.0). Source code: '
      'https://github.com/mikejr83/rc-soar-score',
    );
  });
}
