import 'package:flutter/material.dart';

/// What changing a setting means, so the page can say it without colour.
enum SettingKind {
  details(
    Icons.info_outline,
    'Contest details',
    'The contest’s name, dates and venue',
  ),
  structural(
    Icons.account_tree_outlined,
    'Structural',
    'Changes how the matrix is drawn',
  ),
  rules(Icons.rule, 'Scoring rules', 'Defines how flights are scored'),
  recalc(
    Icons.calculate_outlined,
    'Recalculating',
    'Saving after scoring starts recalculates results',
  ),
  present(
    Icons.visibility_outlined,
    'Presentation',
    'Display and participant options',
  );

  const SettingKind(this.icon, this.label, this.description);

  final IconData icon;
  final String label;
  final String description;
}
