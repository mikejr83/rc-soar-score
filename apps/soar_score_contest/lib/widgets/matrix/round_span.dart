import '../../l10n/app_localizations.dart';

/// "round 3" or "rounds 3 to 5", for the middle of a sentence.
String roundSpan(AppLocalizations l10n, int first, int last) =>
    l10n.matrixRoundSpan(last - first + 1, first, last);
