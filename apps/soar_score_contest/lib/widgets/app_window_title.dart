import 'package:flutter/material.dart';

import '../pages/landing_page.dart';
import '../services/window/window_title_channel.dart';

/// The window title for the current context: the application name, followed
/// by the selected contest's name when there is one.
String windowTitleFor({String? contestName}) => contestName == null
    ? LandingPage.title
    : '${LandingPage.title}: $contestName';

/// Applies [title] to the application window: the browser tab on web (through
/// [Title]) and the title bar on Windows desktop (through
/// [WindowTitleChannel]).
///
/// Each top-level page tree (the landing page and the shell) sets its own
/// title, so the most recently shown tree wins.
class AppWindowTitle extends StatefulWidget {
  const AppWindowTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<AppWindowTitle> createState() => _AppWindowTitleState();
}

class _AppWindowTitleState extends State<AppWindowTitle> {
  @override
  void initState() {
    super.initState();
    WindowTitleChannel.setTitle(widget.title);
  }

  @override
  void didUpdateWidget(AppWindowTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      WindowTitleChannel.setTitle(widget.title);
    }
  }

  @override
  Widget build(BuildContext context) => Title(
    title: widget.title,
    color: Theme.of(context).colorScheme.primary,
    child: widget.child,
  );
}
