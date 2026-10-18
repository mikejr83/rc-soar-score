import 'package:flutter/material.dart';

import '../../models/results/contest_header.dart';

/// Name, dates, venue and status of a contest.
class ContestHeaderCard extends StatelessWidget {
  const ContestHeaderCard({super.key, required this.header});

  final ContestHeader header;

  static String formatDates(DateTime? start, DateTime? end) {
    String day(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (start == null) return end == null ? '' : day(end);
    if (end == null || day(start) == day(end)) return day(start);
    return '${day(start)} to ${day(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(header.name, style: text.headlineSmall)),
            Chip(label: Text(header.status)),
          ],
        ),
        const SizedBox(height: 4),
        Text(formatDates(header.start, header.end), style: text.bodyLarge),
        if (header.venue.isNotEmpty) Text(header.venue),
        if (header.discipline.isNotEmpty) Text(header.discipline),
      ],
    );
  }
}
