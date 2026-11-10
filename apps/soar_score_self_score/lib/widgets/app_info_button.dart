import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';

enum _Entry { copyInvitation, appInfo }

/// The action menu in the app bar (three dots). It leads to the Application
/// info page, where the open source licences, the Privacy Policy and the
/// Terms are listed. A page can add "Copy invitation link" to it.
class AppInfoButton extends StatelessWidget {
  const AppInfoButton({this.onCopyInvitationLink, super.key});

  /// When set, the menu leads with "Copy invitation link".
  final VoidCallback? onCopyInvitationLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_Entry>(
      tooltip: l10n.moreMenuTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: (entry) {
        switch (entry) {
          case _Entry.copyInvitation:
            onCopyInvitationLink?.call();
          case _Entry.appInfo:
            context.push(appInfoPath);
        }
      },
      itemBuilder: (context) => [
        if (onCopyInvitationLink != null)
          PopupMenuItem(
            value: _Entry.copyInvitation,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(l10n.copyInvitationLink),
            ),
          ),
        PopupMenuItem(
          value: _Entry.appInfo,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appInfoLink),
          ),
        ),
      ],
    );
  }
}
