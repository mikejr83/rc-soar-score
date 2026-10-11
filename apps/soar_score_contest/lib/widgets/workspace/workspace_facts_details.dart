import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../contest_list.dart';
import '../detail_section_card.dart';

/// The contest's dates, time zone, host and location. Stands in for the
/// contest-facts widget until it lands.
class WorkspaceFactsDetails extends StatelessWidget {
  const WorkspaceFactsDetails({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final location = [
      contest.city,
      contest.state,
      contest.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return DetailSectionCard(
      title: 'Contest',
      items: [
        DetailItem('Dates', ContestList.contestDates(contest)),
        DetailItem('Timezone', contest.timezone),
        DetailItem('Host', contest.host),
        DetailItem('Location', location),
      ],
    );
  }
}
