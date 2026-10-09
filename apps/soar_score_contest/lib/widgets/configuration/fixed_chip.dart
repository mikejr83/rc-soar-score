import 'package:flutter/material.dart';

/// The `Fixed` tag of a setting the contest's state has locked. The reason
/// is its tooltip and its accessible name (`Fixed: <reason>`), and the chip
/// can be focused and tapped, so the reason is reachable without a mouse.
class FixedChip extends StatefulWidget {
  const FixedChip({super.key, required this.reason});

  /// Why the setting is fixed, for example `Fixed once scoring has started.`
  final String reason;

  @override
  State<FixedChip> createState() => _FixedChipState();
}

class _FixedChipState extends State<FixedChip> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      focusable: true,
      label: 'Fixed: ${widget.reason}',
      excludeSemantics: true,
      child: Tooltip(
        key: _tooltip,
        message: widget.reason,
        triggerMode: TooltipTriggerMode.manual,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _tooltip.currentState?.ensureTooltipVisible(),
          child: Container(
            height: 24,
            padding: const EdgeInsets.only(left: 6, right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  'Fixed',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
