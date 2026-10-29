import 'package:flutter/material.dart';

import '../../services/participants/participant_row.dart';
import 'team_avatar.dart';

/// A choice in the team picker.
class _TeamChoice {
  const _TeamChoice({
    required this.value,
    required this.label,
    required this.subtitle,
    this.icon,
  });

  /// The team name to set ('' for no team).
  final String value;
  final String label;
  final String subtitle;

  /// Shown instead of the team avatar (create, clear).
  final IconData? icon;
}

/// The team input of a participant row: free text with a picker of the
/// existing teams (matched ignoring case), `Create team "…"` for a new name
/// and `No team` to clear it. A pilot with no team is unassigned, which is
/// not an error.
class TeamCell extends StatefulWidget {
  const TeamCell({
    super.key,
    required this.value,
    required this.teams,
    required this.onChanged,
    required this.normalize,
    required this.focusNode,
    required this.semanticLabel,
    this.onSubmitted,
    this.height = 40,
    this.enabled = true,
    this.changed = false,
  });

  final String value;
  final List<TeamSummary> teams;

  /// Sets the team (already normalized).
  final ValueChanged<String> onChanged;

  /// Turns typed text into a team name (existing spelling or title case).
  final String Function(String typed) normalize;

  final FocusNode focusNode;
  final String semanticLabel;
  final VoidCallback? onSubmitted;
  final double height;

  /// Whether the team can change.
  final bool enabled;

  /// The team was edited since the last save (a primary outline).
  final bool changed;

  @override
  State<TeamCell> createState() => _TeamCellState();
}

class _TeamCellState extends State<TeamCell> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(TeamCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_focusChanged);
      widget.focusNode.addListener(_focusChanged);
    }
    if (!widget.focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
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
      _commit(_controller.text);
    }
    setState(() {});
  }

  void _commit(String typed) {
    final team = widget.normalize(typed);
    if (_controller.text != team) {
      _controller.text = team;
    }
    if (team != widget.value) {
      widget.onChanged(team);
    }
  }

  Iterable<_TeamChoice> _choices(String typed) {
    final query = typed.trim().toLowerCase();
    final current = widget.value.trim().toLowerCase();
    final choices = <_TeamChoice>[
      for (final team in widget.teams)
        if (query.isEmpty || team.name.toLowerCase().contains(query))
          _TeamChoice(
            value: team.name,
            label: team.name,
            subtitle:
                '${team.count} participant${team.count == 1 ? '' : 's'}'
                '${query.isNotEmpty && team.name.toLowerCase() == query && team.name != typed.trim() ? ' · existing team, case ignored' : ''}',
          ),
    ];
    final exact = widget.teams.any((team) => team.name.toLowerCase() == query);
    if (query.isNotEmpty && !exact) {
      choices.add(
        _TeamChoice(
          value: titleCase(typed),
          label: 'Create team “${titleCase(typed)}”',
          subtitle: 'New team',
          icon: Icons.add,
        ),
      );
    }
    if (query.isNotEmpty || current.isNotEmpty) {
      choices.add(
        const _TeamChoice(
          value: '',
          label: 'No team',
          subtitle: 'Clear the name. The pilot stays unassigned.',
          icon: Icons.person_off_outlined,
        ),
      );
    }
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focused = widget.focusNode.hasFocus;
    final team = widget.value.trim();
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: RawAutocomplete<_TeamChoice>(
        textEditingController: _controller,
        focusNode: widget.focusNode,
        displayStringForOption: (choice) => choice.value,
        optionsBuilder: (value) => _choices(value.text),
        onSelected: (choice) {
          _controller.text = choice.value;
          if (choice.value != widget.value) {
            widget.onChanged(choice.value);
          }
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              style: theme.textTheme.bodyMedium,
              onSubmitted: (text) {
                _commit(text);
                widget.onSubmitted?.call();
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Unassigned',
                constraints: BoxConstraints.tightFor(height: widget.height),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                filled: !widget.enabled,
                fillColor: scheme.onSurface.withValues(alpha: 0.12),
                border: border(scheme.outline),
                enabledBorder: widget.changed
                    ? border(scheme.primary, 2)
                    : border(scheme.outline),
                focusedBorder: border(scheme.primary, 2),
                disabledBorder: border(Colors.transparent),
                prefixIcon: team.isNotEmpty && !focused
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: TeamAvatar(team: team),
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
              ),
            ),
        optionsViewBuilder: (context, onSelected, choices) => Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 3,
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280, maxHeight: 320),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                children: [
                  for (final (index, choice) in choices.indexed) ...[
                    if (index > 0 && choice.icon != null)
                      Divider(height: 1, color: scheme.outlineVariant),
                    ListTile(
                      dense: true,
                      leading: choice.icon == null
                          ? TeamAvatar(team: choice.value, size: 28)
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: scheme.surfaceContainerHighest,
                              child: Icon(choice.icon, size: 18),
                            ),
                      title: Text(choice.label),
                      subtitle: Text(choice.subtitle),
                      onTap: () => onSelected(choice),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
