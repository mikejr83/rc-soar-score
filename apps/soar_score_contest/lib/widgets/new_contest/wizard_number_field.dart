import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A short whole-number input for a setting (rounds, groups).
///
/// It keeps what is typed so an invalid value stays on screen until fixed.
/// Optional steppers make it quick to change with a pointer.
class WizardNumberField extends StatefulWidget {
  const WizardNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.error = false,
    this.enabled = true,
    this.steppers = false,
    this.min = 1,
    this.max,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String semanticLabel;
  final bool error;
  final bool enabled;

  /// Shows − and + buttons beside the input.
  final bool steppers;
  final int min;
  final int? max;

  @override
  State<WizardNumberField> createState() => _WizardNumberFieldState();
}

class _WizardNumberFieldState extends State<WizardNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(WizardNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final current = int.tryParse(_controller.text.trim()) ?? widget.min;
    var next = current + delta;
    if (next < widget.min) {
      next = widget.min;
    }
    if (widget.max != null && next > widget.max!) {
      next = widget.max!;
    }
    widget.onChanged('$next');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = int.tryParse(widget.value.trim());
    final field = SizedBox(
      width: 96,
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          enabledBorder: widget.error
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: scheme.error, width: 2),
                )
              : null,
        ),
      ),
    );
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: widget.steppers
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  tooltip: 'Fewer',
                  onPressed:
                      widget.enabled &&
                          (current == null || current > widget.min)
                      ? () => _step(-1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                field,
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'More',
                  onPressed:
                      widget.enabled &&
                          (widget.max == null ||
                              current == null ||
                              current < widget.max!)
                      ? () => _step(1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          : field,
    );
  }
}
