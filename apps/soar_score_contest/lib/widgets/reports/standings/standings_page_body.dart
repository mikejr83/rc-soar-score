import 'package:flutter/material.dart';

import '../../../services/reports/standings/standings_key.dart';
import '../../../services/reports/standings/standings_layout.dart';
import '../../../services/reports/standings/standings_table.dart';
import '../viewer/paper_style.dart';
import 'standings_table_view.dart';

/// The body of one printed page of the standings: which pilots and rounds the
/// page holds, the table, and under it where the rounds continue and the key.
class StandingsPageBody extends StatelessWidget {
  const StandingsPageBody({
    super.key,
    required this.table,
    required this.layout,
    required this.page,
    required this.format,
    required this.partialRounds,
    required this.preview,
    required this.size,
  });

  final StandingsTable table;
  final StandingsLayout layout;
  final StandingsPageSpec page;
  final StandingsFormat format;
  final Map<int, String> partialRounds;
  final bool preview;

  /// The room the page body has.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final note = StandingsKey.continuation(page: page, layout: layout);
    final key = StandingsKey.items(
      table: table,
      page: page,
      partialRounds: partialRounds,
    );
    const small = TextStyle(fontSize: 9.5, height: 13 / 9.5);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              StandingsKey.indicator(page: page),
              style: PaperStyle.body.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: StandingsTableView(
              table: table,
              page: page,
              format: format,
              partialRounds: partialRounds,
              preview: preview,
            ),
          ),
          const Spacer(),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: small.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PaperStyle.ink)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 16,
                runSpacing: 2,
                children: [
                  Text(
                    'Key',
                    style: small.copyWith(fontWeight: FontWeight.w700),
                  ),
                  for (final item in key) Text(item, style: small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
