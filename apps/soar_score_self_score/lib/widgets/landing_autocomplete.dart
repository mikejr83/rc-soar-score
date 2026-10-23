import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/landing_result.dart';
import '../services/landing_search.dart';

/// Combobox for landing tables too large for a sheet. The pilot types part of
/// a label, picks one match, and that single result is selected. Text that
/// matches nothing selects nothing and says so.
class LandingAutocompleteField extends StatefulWidget {
  const LandingAutocompleteField({
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

  @override
  State<LandingAutocompleteField> createState() =>
      _LandingAutocompleteFieldState();
}

class _LandingAutocompleteFieldState extends State<LandingAutocompleteField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selected?.label ?? '';
  }

  @override
  void didUpdateWidget(LandingAutocompleteField old) {
    super.didUpdateWidget(old);
    // The form cleared landing (late landing, out of bounds): drop the text.
    if (old.selected != null && widget.selected == null) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _noMatch =>
      widget.selected == null &&
      _controller.text.trim().isNotEmpty &&
      searchLandingTable(widget.table, _controller.text).isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RawAutocomplete<LandingResult>(
      textEditingController: _controller,
      focusNode: _focus,
      displayStringForOption: (result) => result.label,
      optionsBuilder: (value) =>
          widget.enabled ? searchLandingTable(widget.table, value.text) : [],
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        enabled: widget.enabled,
        style: theme.textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: 'Type a label or number',
          errorText: _noMatch ? 'Not on the landing table' : null,
          suffixText: widget.selected == null
              ? null
              : '${widget.selected!.points} points',
          suffixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BrandTheme.buttonRadius),
          ),
        ),
        onChanged: (text) {
          // Editing after a pick drops the pick until a match is chosen.
          if (widget.selected != null && text != widget.selected!.label) {
            widget.onChanged(null);
          }
          setState(() {});
        },
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(BrandTheme.radius),
          color: scheme.surfaceContainerLowest,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final result = options.elementAt(index);
                return ListTile(
                  minTileHeight: 48,
                  title: Text(result.label),
                  trailing: Text(
                    '${result.points}',
                    style: BrandTypography.numbers.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => onSelected(result),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
