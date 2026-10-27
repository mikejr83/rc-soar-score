import 'package:flutter/material.dart';

/// A participant option in step 3 of the New Contest wizard. Each one adds
/// columns to the Participants step, and says so.
enum ParticipantOption {
  teams(
    title: 'Teams',
    icon: Icons.diversity_3,
    description: 'Group pilots into teams for a team score.',
    effect:
        'Adds a Team column. Type a name to create a team. Pilots with no '
        'team are unassigned. Team protection becomes available in Draw '
        'options.',
  ),
  pilotNumbers(
    title: 'Contest pilot numbers',
    icon: Icons.pin_outlined,
    description: 'Give each pilot a number for this contest.',
    effect: 'Adds a Pilot no. column. Numbers are assigned at the first draw.',
    note: 'Any number shown before the first draw is labelled provisional.',
  ),
  classes(
    title: 'Classes',
    icon: Icons.workspace_premium_outlined,
    description: 'Score pilots in classes such as Open or Sportsman.',
    effect: 'Adds a required Class column for every scoring pilot.',
  ),
  roles(
    title: 'Contest roles',
    icon: Icons.badge_outlined,
    description: 'Include non-flying people such as timers and the CD.',
    effect:
        'Adds a Role column. New people start as Pilot. Non-flying roles get '
        'no score rows.',
  ),
  models(
    title: 'Pilot models',
    icon: Icons.flight,
    description: 'Record the models each pilot flies.',
    effect: 'Adds a Models column for scoring pilots.',
    note:
        'Model details can’t be recorded yet. The column says so until they '
        'can.',
  );

  const ParticipantOption({
    required this.title,
    required this.icon,
    required this.description,
    required this.effect,
    this.note,
  });

  final String title;
  final IconData icon;
  final String description;

  /// How the option changes the Participants step.
  final String effect;

  /// Shown under the option while it is on.
  final String? note;
}
