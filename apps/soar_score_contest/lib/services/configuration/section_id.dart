import 'setting_kind.dart';

/// The sections of the configuration page, in the order of the brief.
enum SectionId {
  details(
    title: 'Contest details',
    short: 'Details',
    purpose: 'Who runs the contest, where and when.',
    kinds: [],
  ),
  discipline(
    title: 'Discipline and rules',
    short: 'Discipline',
    purpose: 'The discipline this contest flies and the options it defines.',
    kinds: [SettingKind.rules],
  ),
  landing(
    title: 'Landing table',
    short: 'Landing table',
    purpose: 'The distance-to-points lookup scorers use for landing bonuses.',
    kinds: [SettingKind.rules],
  ),
  scoring(
    title: 'Scoring',
    short: 'Scoring',
    purpose: 'How flights become group scores, totals and team scores.',
    kinds: [SettingKind.recalc],
  ),
  participantOptions(
    title: 'Participant options',
    short: 'Participant options',
    purpose: 'What the Participants page tracks for each person.',
    kinds: [SettingKind.structural, SettingKind.present],
    mixed: true,
  ),
  participants(
    title: 'Participants',
    short: 'Participants',
    purpose: 'Who is entered. Edit participants on the Participants page.',
    kinds: [],
  ),
  draw(
    title: 'Draw options',
    short: 'Draw options',
    purpose: 'How the Matrix page puts pilots into groups and lanes.',
    kinds: [SettingKind.structural, SettingKind.present],
    mixed: true,
  ),
  scoringAccess(
    title: 'Scoring access',
    short: 'Scoring access',
    purpose: 'Whether participants may submit scores.',
    kinds: [],
  ),
  adminLock(
    title: 'Administration lock',
    short: 'Admin lock',
    purpose: 'Whether the contest can still be administered.',
    kinds: [],
  ),
  publicUpdates(
    title: 'Public updates and reviews',
    short: 'Public updates',
    purpose:
        'When the public site changes, and whether pilots can ask for reviews.',
    kinds: [SettingKind.present],
  );

  const SectionId({
    required this.title,
    required this.short,
    required this.purpose,
    required this.kinds,
    this.mixed = false,
  });

  final String title;

  /// The label in the section list and chip row.
  final String short;
  final String purpose;
  final List<SettingKind> kinds;

  /// Whether each row also names its kind, because the section mixes kinds.
  final bool mixed;
}
