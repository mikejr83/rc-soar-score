import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../contest_list.dart';
import '../detail_section_card.dart';

/// The contest's dates, time zone, host and location. Stands in for the
/// contest-facts widget until it lands.
class WorkspaceFactsDetails extends StatelessWidget {
  const WorkspaceFactsDetails({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final location = [
      contest.city,
      contest.state,
      contest.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return DetailSectionCard(
      title: l10n.workspaceFactsTitle,
      items: [
        DetailItem(l10n.workspaceFactsDates, ContestList.contestDates(l10n, contest)),
        DetailItem(l10n.workspaceFactsTimezone, contest.timezone),
        DetailItem(l10n.workspaceFactsHost, contest.host),
        DetailItem(l10n.workspaceFactsLocation, location),
      ],
    );
  }
}
