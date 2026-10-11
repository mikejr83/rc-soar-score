import 'package:flutter/material.dart';

/// A polite live region: assistive technology reads [message] when it
/// changes. It draws nothing.
class WorkspaceLiveRegion extends StatelessWidget {
  const WorkspaceLiveRegion({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: message,
    child: const SizedBox(width: 1, height: 1),
  );
}
