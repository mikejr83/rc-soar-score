// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get moreMenuTooltip => 'More';

  @override
  String get openSourceLicencesLink => 'Open source licences';

  @override
  String get licencesInThisAppLink => 'Licences in this app';

  @override
  String get privacyPolicyLink => 'Privacy Policy';

  @override
  String get termsLink => 'Terms';

  @override
  String get linkOpenFailed =>
      'Could not open the link. Check your network connection and try again.';
}
