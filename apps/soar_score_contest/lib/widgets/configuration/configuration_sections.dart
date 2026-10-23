import 'package:flutter/material.dart';

import '../../services/configuration/configuration_data.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/draw_readiness.dart';
import '../../services/configuration/house_rules.dart';
import '../../services/configuration/readiness_summary.dart';
import '../../services/configuration/section_id.dart';
import '../../services/configuration/section_notice.dart';
import 'config_chip.dart';
import 'config_section_card.dart';
import 'contest_state_section_body.dart';
import 'field_registry.dart';
import 'landing_section_body.dart';
import 'matrix_readiness_panel.dart';
import 'participants_section_body.dart';
import 'setting_field.dart';

/// The section cards of the page, one per [SectionId], each with its own key
/// so the section list can scroll to it and follow the scroll.
class ConfigurationSections extends StatelessWidget {
  const ConfigurationSections({
    super.key,
    required this.data,
    required this.draft,
    required this.registry,
    required this.sectionKeys,
    required this.editable,
    required this.inlineReadiness,
    required this.onChanged,
    required this.onFix,
    required this.onOpenLandings,
    required this.onOpenParticipants,
    required this.onGoToMatrix,
    required this.onOpenWorkspace,
  });

  final ConfigurationData data;
  final ConfigurationDraft draft;
  final FieldRegistry registry;
  final Map<SectionId, GlobalKey> sectionKeys;

  /// False while the page is read-only or a save is running.
  final bool editable;

  /// Show the readiness panel at the end of Draw options (narrow pages).
  final bool inlineReadiness;
  final VoidCallback onChanged;
  final void Function(BlockerFix fix) onFix;
  final VoidCallback onOpenLandings;
  final VoidCallback onOpenParticipants;
  final VoidCallback onGoToMatrix;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final id in SectionId.values) ...[
        KeyedSubtree(key: sectionKeys[id], child: _section(context, id)),
        const SizedBox(height: 20),
      ],
    ],
  );

  Widget _section(BuildContext context, SectionId id) {
    final readOnly = data.readOnly;
    final children = switch (id) {
      SectionId.landing => [
        LandingSectionBody(
          data: data,
          draft: draft,
          registry: registry,
          editable: editable,
          onChanged: onChanged,
          onOpenLandings: onOpenLandings,
        ),
      ],
      SectionId.participants => [
        ParticipantsSectionBody(
          data: data,
          draft: draft,
          onOpenParticipants: onOpenParticipants,
        ),
      ],
      SectionId.scoringAccess || SectionId.adminLock => [
        ContestStateSectionBody(
          id: id,
          contest: data.contest,
          onOpenWorkspace: onOpenWorkspace,
        ),
      ],
      _ => [
        for (final def in draft.catalog.inSection(id))
          if (draft.isVisible(def.key))
            SettingField(
              key: ValueKey('field-${def.key}'),
              def: def,
              draft: draft,
              registry: registry,
              editable: editable,
              onChanged: onChanged,
            ),
        if (id == SectionId.draw && inlineReadiness)
          MatrixReadinessPanel(
            inline: true,
            summary: ReadinessSummary.of(data, draft),
            onFix: onFix,
            onGoToMatrix: onGoToMatrix,
          ),
      ],
    };
    return ConfigSectionCard(
      id: id,
      notices: SectionNotice.of(id, data.phase, readOnly: readOnly),
      extraChips: [
        // The roster is counted from participation records, which have
        // revisions of their own, so it has no single revision to show.
        if (id == SectionId.discipline) _disciplineChip(context),
        if (id == SectionId.participants)
          ConfigChip.neutral(
            context,
            icon: Icons.visibility_outlined,
            text: 'Summary only',
            dense: false,
          ),
      ],
      children: children,
    );
  }

  Widget _disciplineChip(BuildContext context) {
    final houseRules = HouseRules.count(
      draft.catalog.disciplineSettings,
      (def) => draft[def.key],
    );
    return houseRules == 0
        ? ConfigChip.neutral(
            context,
            icon: Icons.verified_outlined,
            text: draft.catalog.defaultLabel,
            tooltip: 'Every option matches the ${draft.catalog.defaultLabel}',
            dense: false,
          )
        : ConfigChip.houseRule(
            context,
            text: '$houseRules house rule${houseRules == 1 ? '' : 's'}',
            dense: false,
          );
  }
}
