import 'package:flutter/material.dart';

/// A button in an [EditorBanner].
class EditorBannerAction {
  const EditorBannerAction(this.label, this.onPressed, {this.icon, this.key});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Key? key;
}

/// A rounded notice with an icon, a title, a sentence and optional actions.
///
/// The colors say what kind of notice it is (error, conflict, decision) but
/// the icon and the words carry the meaning too. The last action is the
/// filled one.
class EditorBanner extends StatelessWidget {
  const EditorBanner({
    required this.icon,
    required this.title,
    required this.background,
    required this.foreground,
    this.body,
    this.actions = const [],
    this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Color background;
  final Color foreground;
  final List<EditorBannerAction> actions;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                        if (body != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            body!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ?child,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, action) in actions.indexed)
                      _button(action, primary: i == actions.length - 1),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(EditorBannerAction action, {required bool primary}) {
    final label = Text(action.label);
    final icon = action.icon == null ? null : Icon(action.icon, size: 18);
    if (primary) {
      final style = FilledButton.styleFrom(
        backgroundColor: foreground,
        foregroundColor: background,
      );
      return icon == null
          ? FilledButton(
              key: action.key,
              style: style,
              onPressed: action.onPressed,
              child: label,
            )
          : FilledButton.icon(
              key: action.key,
              style: style,
              onPressed: action.onPressed,
              icon: icon,
              label: label,
            );
    }
    final style = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground),
    );
    return icon == null
        ? OutlinedButton(
            key: action.key,
            style: style,
            onPressed: action.onPressed,
            child: label,
          )
        : OutlinedButton.icon(
            key: action.key,
            style: style,
            onPressed: action.onPressed,
            icon: icon,
            label: label,
          );
  }
}
