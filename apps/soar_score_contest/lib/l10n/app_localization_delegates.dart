import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

/// App strings and the delegates for the standalone design libraries.
const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
