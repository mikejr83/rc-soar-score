import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/landing_result.dart';

/// Field that shows the chosen landing and opens [LandingSheet] on tap.
class LandingSheetField extends StatelessWidget {
  const LandingSheetField({
    required this.table,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final List<LandingResult> table;
  final LandingResult? selected;
  final bool enabled;
  final ValueChanged<LandingResult?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<LandingResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LandingSheet(table: table, selected: selected),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = selected;
    final muted = scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Landing',
      value: value == null
          ? 'Not chosen'
          : '${value.label}, ${value.points} points',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: enabled ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(BrandTheme.buttonRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled ? scheme.surfaceContainerLowest : scheme.surface,
              borderRadius: BorderRadius.circular(BrandTheme.buttonRadius),
              border: Border.all(
                color: enabled ? scheme.outline : scheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: value == null
                      ? Text(
                          'Choose landing',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: muted,
                          ),
                        )
                      : Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: value.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' · ${value.points} points'),
                            ],
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                ),
                Icon(Icons.expand_more, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom sheet: one row per result with its label, note and points.
/// Tapping a row chooses it and closes the sheet.
class LandingSheet extends StatelessWidget {
  const LandingSheet({required this.table, required this.selected, super.key});

  final List<LandingResult> table;
  final LandingResult? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: table.length > 6 ? 0.9 : 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Landing', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        "Choose where you landed. Points come from this "
                        "contest's landing table.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: RadioGroup<String>(
              groupValue: selected?.id,
              onChanged: (id) =>
                  Navigator.of(context)
                      .pop(table.firstWhere((result) => result.id == id)),
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: table.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _LandingOption(result: table[index], scheme: scheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingOption extends StatelessWidget {
  const _LandingOption({required this.result, required this.scheme});

  final LandingResult result;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = RadioGroup.maybeOf<String>(context);
    final isSelected = group?.groupValue == result.id;
    return Material(
      color: isSelected
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandTheme.radius),
        side: BorderSide(
          color: isSelected ? scheme.onSurface : scheme.outlineVariant,
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandTheme.radius),
        ),
        onTap: () => group?.onChanged(result.id),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Radio<String>(value: result.id),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (result.description != null)
                      Text(
                        result.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${result.points}',
                style: BrandTypography.numbers.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
