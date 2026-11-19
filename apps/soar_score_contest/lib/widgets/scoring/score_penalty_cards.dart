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
    required this.cumulativeController,
    required this.cumulativeFocusNode,
    required this.cumulativeOnChanged,
    this.cumulativeErrorText,
    this.focusOrder = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final Key fieldKey;

  final TextEditingController cumulativeController;
  final FocusNode cumulativeFocusNode;
  final ValueChanged<String> cumulativeOnChanged;
  final String? cumulativeErrorText;

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
    // The design's "pts" sits inside the field even while it is empty, which
    // `suffixText` does not do.
    final ptsSuffix = Padding(
      padding: const EdgeInsets.only(right: 10, left: 4),
      child: Text(
        'pts',
        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      ),
    );
    final helpStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: scheme.onSurface,
    );
    final helpBold = helpStyle?.copyWith(fontWeight: FontWeight.bold);
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
                      suffixIcon: ptsSuffix,
                      suffixIconConstraints: const BoxConstraints(),
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
                    TextSpan(text: 'this flight', style: helpBold),
                    const TextSpan(text: ' (never below 0). '),
                    TextSpan(text: 'Dropped', style: helpBold),
                    const TextSpan(text: ' if this round is dropped.'),
                  ],
                ),
                style: helpStyle,
              ),
            ],
          ),
        );
        // The three states of the field: empty = never applied, a number > 0
        // = applied, 0 = applied earlier and removed.
        final cumText = cumulativeController.text.trim();
        final cum = int.tryParse(cumText);
        String cumState;
        IconData cumStateIcon;
        var cumStateColor = scheme.onSurface;
        if (cumText.isEmpty) {
          cumState = 'No cumulative penalty.';
          cumStateIcon = Icons.do_not_disturb_on;
        } else if (cum == null || cum < 0) {
          cumState = 'A whole number of points, 0 or more.';
          cumStateIcon = Icons.error_outline;
          cumStateColor = scheme.error;
        } else if (cum == 0) {
          cumState = 'Removed. Removing is recorded as an official correction.';
          cumStateIcon = Icons.remove_circle_outline;
        } else {
          cumState = 'Applied: −$cum points from the contest total.';
          cumStateIcon = Icons.push_pin;
        }
        final cumulative = card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(Icons.push_pin, 'Cumulative penalty'),
              const SizedBox(height: 6),
              SizedBox(
                width: 160,
                child: FocusStep(
                  order: 9,
                  badge: focusOrder ? '9' : null,
                  child: TextField(
                    key: const ValueKey('cumulative-penalty'),
                    controller: cumulativeController,
                    focusNode: cumulativeFocusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: cumulativeOnChanged,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'None',
                      suffixIcon: ptsSuffix,
                      suffixIconConstraints: const BoxConstraints(),
                      errorText: cumulativeErrorText,
                      border: border(),
                      enabledBorder: border(),
                      focusedBorder: border(scheme.primary, 3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(cumStateIcon, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cumState,
                      style: helpStyle?.copyWith(color: cumStateColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Deducted from the '),
                    TextSpan(text: 'contest total', style: helpBold),
                    const TextSpan(text: '. '),
                    TextSpan(text: 'Never dropped', style: helpBold),
                    const TextSpan(
                      text: ', and still counts if this flight is re-flown.',
                    ),
                  ],
                ),
                style: helpStyle,
              ),
            ],
          ),
        );
        return two
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: flight),
                    const SizedBox(width: 12),
                    Expanded(child: cumulative),
                  ],
                ),
              )
            : Column(
                children: [flight, const SizedBox(height: 12), cumulative],
              );
      },
    );
  }
}
