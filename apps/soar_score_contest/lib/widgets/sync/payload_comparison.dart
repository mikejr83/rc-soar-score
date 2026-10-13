import 'package:flutter/material.dart';

/// Two versions of one record side by side, one row per field. Rows whose
/// values differ are marked so the director sees what the choice changes.
class PayloadComparison extends StatelessWidget {
  const PayloadComparison({
    super.key,
    required this.acceptedLabel,
    required this.competingLabel,
    required this.accepted,
    required this.competing,
  });

  final String acceptedLabel;
  final String competingLabel;
  final Map<String, Object?>? accepted;
  final Map<String, Object?>? competing;

  /// The field names of both versions, in order.
  static List<String> fieldsOf(
    Map<String, Object?>? accepted,
    Map<String, Object?>? competing,
  ) => {...?accepted?.keys, ...?competing?.keys}.toList()..sort();

  static String show(Map<String, Object?>? payload, String field) {
    if (payload == null || !payload.containsKey(field)) return '—';
    final value = payload[field];
    return value == null ? 'none' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = fieldsOf(accepted, competing);
    if (accepted == null && competing == null) {
      return const Text(
        'The service sent no values for this conflict.',
        key: ValueKey('conflict-no-values'),
      );
    }
    return Table(
      key: const ValueKey('conflict-comparison'),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            _cell(theme, acceptedLabel, header: true),
            _cell(theme, competingLabel, header: true),
          ],
        ),
        for (final field in fields)
          TableRow(
            key: ValueKey('conflict-field-$field'),
            decoration: show(accepted, field) == show(competing, field)
                ? null
                : BoxDecoration(color: theme.colorScheme.tertiaryContainer),
            children: [
              _cell(theme, field, header: true),
              _cell(theme, show(accepted, field)),
              _cell(theme, show(competing, field)),
            ],
          ),
      ],
    );
  }

  Widget _cell(ThemeData theme, String text, {bool header = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      text,
      style: header ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium,
    ),
  );
}
