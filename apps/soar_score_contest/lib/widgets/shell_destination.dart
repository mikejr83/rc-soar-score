import 'package:flutter/material.dart';

/// One navigation-rail destination in the application shell. [location] is
/// `null` for destinations whose route does not exist yet; selecting one
/// shows the not-wired-up dialog.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.location,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? location;

  /// Whether [path] is this destination's page or a page below it.
  /// Unwired destinations never match.
  bool matches(String path) {
    final location = this.location;
    return location != null &&
        (path == location || path.startsWith('$location/'));
  }
}
