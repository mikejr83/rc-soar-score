import 'package:flutter/material.dart';

/// A button of a [PageStateView]: its label, what it does and an optional key.
class PageStateAction {
  const PageStateAction({
    required this.label,
    required this.onPressed,
    this.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

/// What a [PageStateView] says about the page.
enum PageStateKind {
  loading(Icons.hourglass_empty),
  empty(Icons.inbox_outlined),
  notFound(Icons.search_off),
  unavailable(Icons.cloud_off),
  authorization(Icons.lock_outline),
  conflict(Icons.sync_problem);

  const PageStateKind(this.icon);

  final IconData icon;
}

/// A page-sized state that replaces a page's content: an icon (or a spinner
/// while loading), a title, an optional body and up to two actions. It is a
/// live region, so a screen reader announces it when it replaces the page. The
/// shell's rail and header stay. An icon and text carry the meaning, never
/// colour alone.
///
/// The text comes from the caller (already localized once its screen is); the
/// widget holds none of its own. Use the named constructors:
///
/// - [PageStateView.loading]: [title] is also the spinner's semantic label.
/// - [PageStateView.empty]: nothing to list yet; the primary action creates.
/// - [PageStateView.unavailable]: could not be loaded or reached; Retry.
/// - [PageStateView.authorization]: not signed in or not allowed.
/// - [PageStateView.conflict]: changed elsewhere; the page supplies the
///   actions, since what resolves it depends on the flow.
/// - [PageStateView.notFound]: the thing does not exist (any more).
class PageStateView extends StatelessWidget {
  const PageStateView.loading({super.key, required String label})
    : kind = PageStateKind.loading,
      title = label,
      body = null,
      primary = null,
      secondary = null,
      action = null;

  const PageStateView.empty({
    super.key,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
    this.action,
  }) : kind = PageStateKind.empty;

  const PageStateView.unavailable({
    super.key,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
  }) : kind = PageStateKind.unavailable,
       action = null;

  const PageStateView.authorization({
    super.key,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
  }) : kind = PageStateKind.authorization,
       action = null;

  const PageStateView.conflict({
    super.key,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
  }) : kind = PageStateKind.conflict,
       action = null;

  const PageStateView.notFound({
    super.key,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
  }) : kind = PageStateKind.notFound,
       action = null;

  final PageStateKind kind;
  final String title;
  final String? body;

  /// The main action, as a filled button (Retry, Create, Back).
  final PageStateAction? primary;

  /// A quieter second action, as a text button.
  final PageStateAction? secondary;

  /// A custom action widget shown under the buttons, for an empty state whose
  /// action depends on state (such as `Create contest` or `Continue`).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = this.primary;
    final secondary = this.secondary;
    final body = this.body;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
            container: true,
            // A live region announces the state when it replaces the page, on
            // every platform. Flutter does not allow a status or alert role on
            // the same node, and roles are only supported on the web.
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kind == PageStateKind.loading)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  )
                else
                  Icon(
                    kind.icon,
                    size: 40,
                    color:
                        kind == PageStateKind.unavailable ||
                            kind == PageStateKind.conflict
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: kind == PageStateKind.loading
                      ? theme.textTheme.bodyLarge
                      : theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (primary != null || secondary != null || action != null)
                  const SizedBox(height: 24),
                if (primary != null)
                  FilledButton(
                    key: primary.key,
                    onPressed: primary.onPressed,
                    child: Text(primary.label),
                  ),
                if (secondary != null) ...[
                  if (primary != null) const SizedBox(height: 8),
                  TextButton(
                    key: secondary.key,
                    onPressed: secondary.onPressed,
                    child: Text(secondary.label),
                  ),
                ],
                ?action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
