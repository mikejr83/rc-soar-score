import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../auth/auth_scope.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import 'app_info_button.dart';

/// The flat top bar: brand mark, an optional context line over the page
/// title, the connection state and the account control.
class SelfScoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelfScoreAppBar({
    required this.title,
    this.contextLine,
    this.onBack,
    this.backLabel,
    this.actions = const [],
    this.showAccount = true,
    this.onCopyInvitationLink,
    super.key,
  });

  final String title;

  /// Small line above the title, such as the contest name.
  final String? contextLine;
  final VoidCallback? onBack;

  /// Tooltip of the back button; the localized "Back" when null.
  final String? backLabel;
  final List<Widget> actions;
  final bool showAccount;

  /// Adds "Copy invitation link" to the action menu when set.
  final VoidCallback? onCopyInvitationLink;

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    tooltip: backLabel ?? l10n.appBarBackTooltip,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BrandLogo(
                      height: 32,
                      semanticLabel: l10n.appBarLogoLabel,
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contextLine != null)
                        Text(
                          contextLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                ...actions,
                if (showAccount)
                  IconButton(
                    tooltip: l10n.appBarAccountTooltip,
                    onPressed: context.auth.isSignedIn
                        ? () => context.go(accountPath)
                        : null,
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                AppInfoButton(onCopyInvitationLink: onCopyInvitationLink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
