import 'package:flutter/material.dart';

import '../models/landing_result.dart';
import '../services/landing_search.dart';
import 'landing_autocomplete.dart';
import 'landing_sheet.dart';

/// The landing field of the entry form. Chooses by table size: a bottom
/// sheet for [landingSheetMaxResults] results or fewer, an autocomplete
/// combobox above that. Both store one [LandingResult] and both are disabled,
/// with [disabledReason] shown in text, when the form clears landing.
class LandingControl extends StatelessWidget {
  const LandingControl({
    required this.table,
    required this.selected,
    required this.onChanged,
    this.disabledReason,
    super.key,
  });

  final List<LandingResult> table;
  final LandingResult? selected;
  final ValueChanged<LandingResult?> onChanged;

  /// Non-null disables the control and explains why.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (landingUsesSheet(table))
          LandingSheetField(
            table: table,
            selected: selected,
            enabled: disabledReason == null,
            onChanged: onChanged,
          )
        else
          LandingAutocompleteField(
            table: table,
            selected: selected,
            enabled: disabledReason == null,
            onChanged: onChanged,
          ),
        const SizedBox(height: 6),
        Text(
          disabledReason ??
              "Choose from this contest's landing table. Points come from the "
                  'table.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
