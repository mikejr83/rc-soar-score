import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Wording for what a landing table's entry keys mean.
String landingUnitLabel(AppLocalizations l10n, LandingInputUnit unit) =>
    switch (unit) {
      LandingInputUnit.meters => l10n.landingsUnitMeters,
      LandingInputUnit.feet => l10n.landingsUnitFeet,
      LandingInputUnit.points => l10n.landingsUnitPoints,
    };
