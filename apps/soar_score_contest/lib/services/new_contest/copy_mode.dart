/// What the New Contest wizard copies from an existing contest (step 1).
///
/// Copying never brings scores, the flight matrix, publication history,
/// invitations, deletion state or audit history
/// (`plan/ui/contest-administration/new-contest-wizard.md`).
enum CopyMode {
  none(
    label: 'Don’t copy',
    description: 'Start with a blank configuration and no pilots.',
  ),
  configuration(
    label: 'Configuration only',
    description: 'Discipline, options, scoring and draw settings.',
  ),
  allPilots(
    label: 'Configuration + all pilots',
    description: 'Every pilot in the source contest, with their class.',
  ),
  selectedPilots(
    label: 'Configuration + selected pilots',
    description:
        'Pick some pilots, with their class, for example for a '
        'fly-off.',
  );

  const CopyMode({required this.label, required this.description});

  final String label;
  final String description;

  /// Whether a source contest is needed.
  bool get usesSource => this != none;

  /// Whether pilots come along with the configuration.
  bool get copiesPilots => this == allPilots || this == selectedPilots;
}
