import 'package:flutter/material.dart';

/// An outlined text field for a setting. It keeps what is typed in its own
/// controller and follows [value] when the draft changes it from elsewhere
/// (Undo, Reset to official, Discard changes).
class SettingTextInput extends StatefulWidget {
  const SettingTextInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.unit,
    this.placeholder,
    this.keyboardType,
    this.maxWidth,
    this.focusNode,
    this.semanticLabel,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool hasError;
  final String? unit;
  final String? placeholder;
  final TextInputType? keyboardType;
  final double? maxWidth;
  final FocusNode? focusNode;
  final String? semanticLabel;

  /// For a field that opens a picker instead of taking typed text.
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  State<SettingTextInput> createState() => _SettingTextInputState();
}

class _SettingTextInputState extends State<SettingTextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(SettingTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = widget.hasError;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: color, width: width),
        );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
      child: Semantics(
        label: widget.semanticLabel,
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            suffixText: widget.unit,
            suffixIcon: widget.suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: border(
              error ? scheme.error : scheme.outline,
              error ? 2 : 1,
            ),
            focusedBorder: border(error ? scheme.error : scheme.primary, 2),
            disabledBorder: border(scheme.onSurface.withValues(alpha: 0.12)),
          ),
        ),
      ),
    );
  }
}
