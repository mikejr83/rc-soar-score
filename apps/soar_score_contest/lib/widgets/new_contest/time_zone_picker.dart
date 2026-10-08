import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// A searchable list of every IANA time zone, labelled for people
/// (`Central European Time · Rome · UTC+02:00`). The value is the zone id.
///
/// Offsets are shown as of [at] (the contest start), so daylight saving
/// matches the day pilots will fly.
class TimeZonePicker extends StatelessWidget {
  const TimeZonePicker({
    super.key,
    required this.zone,
    required this.onChanged,
    this.at,
    this.helperText,
  });

  final String zone;
  final ValueChanged<String> onChanged;
  final DateTime? at;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final ids = ContestTimeZones.ids;
    return LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<String>(
        key: ValueKey('contest-time-zone-$zone'),
        initialSelection: zone,
        width: constraints.maxWidth,
        menuHeight: 320,
        requestFocusOnTap: true,
        enableFilter: true,
        label: const Text('Time zone'),
        helperText: helperText,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        dropdownMenuEntries: [
          for (final id in ids)
            DropdownMenuEntry(
              value: id,
              label: ContestTimeZones.label(id, at: at),
            ),
        ],
        filterCallback: (entries, filter) {
          final matches = ContestTimeZones.search(filter, at: at).toSet();
          return [
            for (final entry in entries)
              if (matches.contains(entry.value)) entry,
          ];
        },
        onSelected: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
