import 'package:flutter/material.dart';

/// The surface every page in the contest shell sits on.
///
/// The shell shows a page in go_router's nested navigator, whose modal barrier
/// plays the system alert for any click no widget catches. A page made of gaps
/// (Column, Padding, Wrap) catches nothing there, so the surface takes every
/// click itself with an opaque, transparent box.
class PageSurface extends StatelessWidget {
  const PageSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(color: Colors.transparent, child: child),
    ),
  );
}
