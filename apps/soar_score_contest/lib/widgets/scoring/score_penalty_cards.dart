import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focus_step.dart';

/// The two penalties as two bordered cards, so the difference reads without
/// a tooltip: this flight and dropped, or the contest total and never dropped.
class ScorePenaltyCards extends StatelessWidget {
  const ScorePenaltyCards({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
    required this.fieldKey,
    this.focusOrder = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final Key fieldKey;
  final bool focusOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget card({required Widget child}) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
    Widget title(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
    OutlineInputBorder border([Color? color, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: color ?? scheme.outline, width: width),
        );
    return LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 520;
        final flight = card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(Icons.remove, 'Flight penalty'),
              const SizedBox(height: 6),
              SizedBox(
                width: 160,
                child: FocusStep(
                  order: 8,
                  badge: focusOrder ? '8↵' : null,
                  enterPath: true,
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmitted(),
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'pts',
                      errorText: errorText,
                      border: border(),
                      enabledBorder: border(),
                      focusedBorder: border(scheme.primary, 3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Deducted from '),
                    TextSpan(
                      text: 'this flight',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' (never below 0). '),
                    TextSpan(
                      text: 'Dropped',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' if this round is dropped.'),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
        final cumulative = card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(Icons.push_pin_outlined, 'Cumulative penalty'),
              const SizedBox(height: 6),
              SizedBox(
                width: 160,
                child: FocusStep(
                  order: 9,
                  badge: focusOrder ? '9' : null,
                  child: const TextField(
                    key: ValueKey('cumulative-penalty'),
                    enabled: false,
                    decoration: InputDecoration(
                      suffixText: 'pts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Taken from the '),
                    TextSpan(
                      text: 'contest total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '. '),
                    TextSpan(
                      text: 'Never dropped',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' with its round. Not available yet: the score '
                          'API does not store it.',
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
        return two
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: flight),
                  const SizedBox(width: 12),
                  Expanded(child: cumulative),
                ],
              )
            : Column(
                children: [flight, const SizedBox(height: 12), cumulative],
              );
      },
    );
  }
}
