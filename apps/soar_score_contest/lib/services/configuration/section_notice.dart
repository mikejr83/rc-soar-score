import 'package:flutter/material.dart';

import 'config_phase.dart';
import 'section_id.dart';
import 'setting_kind.dart';

/// A line under a section's purpose saying what the contest's state does to
/// the section.
class SectionNotice {
  const SectionNotice(this.icon, this.text, {this.warning = false});

  final IconData icon;
  final String text;
  final bool warning;

  /// The notices for [id] in [phase]; none when the page is [readOnly].
  static List<SectionNotice> of(
    SectionId id,
    ConfigPhase phase, {
    required bool readOnly,
  }) {
    if (readOnly) {
      return const [];
    }
    final running = phase.isRunning;
    return [
      if (id == SectionId.details)
        const SectionNotice(
          Icons.info_outline,
          'Not part of the configuration revision. Changes here don’t affect '
          'the matrix or scores.',
        ),
      if (id.kinds.contains(SettingKind.structural))
        if (running)
          SectionNotice(
            Icons.lock_outline,
            'Structural settings are fixed once scoring has started.'
            '${id.mixed ? ' Presentation settings can still change.' : ''}',
          )
        else if (phase.isDrawn)
          const SectionNotice(
            Icons.sync_problem,
            'A matrix is drawn. Saving a structural change makes it out of '
            'date until you redraw on the Matrix page.',
            warning: true,
          ),
      if (id == SectionId.discipline && running)
        const SectionNotice(
          Icons.lock_outline,
          'Discipline options are fixed once scoring has started.',
        ),
      if (id == SectionId.landing && running)
        const SectionNotice(
          Icons.lock_outline,
          'The landing table is fixed once scoring has started.',
        ),
      if (id.kinds.contains(SettingKind.recalc) && running)
        const SectionNotice(
          Icons.calculate_outlined,
          'Scoring has started. Saving a change here recalculates all '
          'results.',
        ),
    ];
  }
}
