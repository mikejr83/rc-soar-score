import 'package:flutter/material.dart';

import '../../services/new_contest/participant_option.dart';

/// One participant option: what it is, how it changes the Participants
/// step, and its switch. [details] shows under it while it is on.
class ParticipantOptionTile extends StatelessWidget {
  const ParticipantOptionTile({
    super.key,
    required this.option,
    required this.value,
    required this.onChanged,
    this.fromSource = false,
    this.details,
  });

  final ParticipantOption option;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Whether the copy source turned the option on.
  final bool fromSource;

  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(option.icon, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          option.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (fromSource && value)
                          Container(
                            height: 22,
                            padding: const EdgeInsetsDirectional.only(
                              start: 4,
                              end: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outlineVariant),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.content_copy,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'From source',
                                  style: small?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          value ? Icons.subdirectory_arrow_right : Icons.add,
                          size: 16,
                          color: value
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${value ? 'In Participants: ' : 'If on: '}'
                            '${option.effect}',
                            style: small?.copyWith(
                              color: value
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Semantics(
                  label: option.title,
                  child: Switch(
                    key: ValueKey('option-${option.name}'),
                    value: value,
                    onChanged: onChanged,
                    thumbIcon: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? const Icon(Icons.check)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (value && details != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 20, 16),
            child: details,
          ),
      ],
    );
  }
}
