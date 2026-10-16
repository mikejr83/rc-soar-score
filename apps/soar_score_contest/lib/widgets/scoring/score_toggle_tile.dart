import 'package:flutter/material.dart';

/// A toggle as a 52 dp tile: a switch track, the label and the state word,
/// with the rule or its reason written under it. A rule that turns it off
/// says why in words.
class ScoreToggleTile extends StatelessWidget {
  const ScoreToggleTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.offReason,
    this.note,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// Why the toggle cannot be changed now, or null.
  final String? offReason;

  /// What turning it on does.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final usable = enabled && offReason == null;
    final fg = usable
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.6);
    final sub = offReason ?? note;
    final track = Container(
      width: 36,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: value ? scheme.primary : scheme.outline,
          width: 2,
        ),
        color: value ? scheme.primary : Colors.transparent,
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? scheme.onPrimary : scheme.outline,
          ),
          child: value
              ? Icon(Icons.check, size: 11, color: scheme.primary)
              : null,
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: usable ? () => onChanged(!value) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            toggled: value,
            enabled: usable,
            label: label,
            excludeSemantics: true,
            onTap: usable ? () => onChanged(!value) : null,
            child: Material(
              color: value
                  ? scheme.secondaryContainer.withValues(alpha: 0.6)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: value ? scheme.primary : scheme.outline,
                  width: value ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: usable ? () => onChanged(!value) : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                    child: Row(
                      children: [
                        track,
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: fg,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          value ? 'On' : 'Off',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                sub,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: offReason != null
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
