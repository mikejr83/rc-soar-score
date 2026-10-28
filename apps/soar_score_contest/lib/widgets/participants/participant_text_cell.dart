import 'package:flutter/material.dart';

/// A compact text input in a participant row (class, model name, model ID),
/// with optional suggestions.
///
/// Changes are reported as they are typed; [onCommit] gets the final text
/// when the cell loses focus (for example to title-case a class). Enter
/// commits and calls [onSubmitted] to move down.
class ParticipantTextCell extends StatefulWidget {
  const ParticipantTextCell({
    super.key,
    required this.value,
    required this.onChanged,
    required this.focusNode,
    required this.semanticLabel,
    this.onCommit,
    this.onSubmitted,
    this.hint,
    this.error = false,
    this.enabled = true,
    this.suggestions = const [],
    this.height = 40,
    this.changed = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCommit;
  final VoidCallback? onSubmitted;
  final FocusNode focusNode;
  final String semanticLabel;
  final String? hint;
  final bool error;
  final bool enabled;
  final List<String> suggestions;
  final double height;

  /// The value was edited since the last save (a primary outline).
  final bool changed;

  @override
  State<ParticipantTextCell> createState() => _ParticipantTextCellState();
}

class _ParticipantTextCellState extends State<ParticipantTextCell> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(ParticipantTextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_focusChanged);
      widget.focusNode.addListener(_focusChanged);
    }
    // Bulk edits and commits change the value from outside.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_focusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (!widget.focusNode.hasFocus) {
      widget.onCommit?.call(_controller.text);
    }
  }

  InputDecoration _decoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      isDense: true,
      hintText: widget.hint,
      filled: !widget.enabled,
      fillColor: scheme.onSurface.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      constraints: BoxConstraints.tightFor(height: widget.height),
      border: border(scheme.outline),
      enabledBorder: widget.error
          ? border(scheme.error, 2)
          : widget.changed
          ? border(scheme.primary, 2)
          : border(scheme.outline),
      focusedBorder: border(widget.error ? scheme.error : scheme.primary, 2),
      disabledBorder: border(Colors.transparent),
      suffixIcon: widget.error
          ? Icon(Icons.error, size: 18, color: scheme.error)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 28),
    );
  }

  Widget _field(BuildContext context) => TextField(
    controller: _controller,
    focusNode: widget.focusNode,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
    onSubmitted: (_) {
      widget.onCommit?.call(_controller.text);
      widget.onSubmitted?.call();
    },
    style: Theme.of(context).textTheme.bodyMedium,
    decoration: _decoration(context),
  );

  @override
  Widget build(BuildContext context) {
    final field = widget.suggestions.isEmpty || !widget.enabled
        ? _field(context)
        : RawAutocomplete<String>(
            textEditingController: _controller,
            focusNode: widget.focusNode,
            optionsBuilder: (value) {
              final typed = value.text.trim().toLowerCase();
              return widget.suggestions.where(
                (option) =>
                    option.toLowerCase().contains(typed) &&
                    option.toLowerCase() != typed,
              );
            },
            onSelected: (option) {
              widget.onChanged(option);
              widget.onCommit?.call(option);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
                _field(context),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 240,
                    maxHeight: 240,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        ListTile(
                          dense: true,
                          title: Text(option),
                          onTap: () => onSelected(option),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: field,
    );
  }
}
