import 'package:flutter/material.dart';

import '../../pages/results/contest_filters.dart';

/// Name, venue and start-date range inputs over the contest list. Owns its
/// text controllers so a rebuild from a URL change keeps the caret in place.
class ContestFilterBar extends StatefulWidget {
  const ContestFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final ContestFilters filters;
  final ValueChanged<ContestFilters> onChanged;

  static const Key nameField = Key('contest_filter_name');
  static const Key venueField = Key('contest_filter_venue');
  static const Key fromField = Key('contest_filter_from');
  static const Key toField = Key('contest_filter_to');
  static const Key clearButton = Key('contest_filter_clear');

  @override
  State<ContestFilterBar> createState() => _ContestFilterBarState();
}

class _ContestFilterBarState extends State<ContestFilterBar> {
  late final _name = TextEditingController(text: widget.filters.name);
  late final _venue = TextEditingController(text: widget.filters.venue);

  @override
  void didUpdateWidget(ContestFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_name, widget.filters.name);
    _sync(_venue, widget.filters.venue);
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text != text) controller.text = text;
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final filters = widget.filters;
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? filters.from : filters.to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    widget.onChanged(
      isFrom
          ? filters.copyWith(from: () => picked)
          : filters.copyWith(to: () => picked),
    );
  }

  Widget _dateField(Key key, String label, DateTime? value, bool isFrom) =>
      SizedBox(
        width: 160,
        child: InkWell(
          key: key,
          onTap: () => _pickDate(isFrom),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(value == null ? '' : ContestFilters.formatDay(value)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            key: ContestFilterBar.nameField,
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (value) =>
                widget.onChanged(filters.copyWith(name: value)),
          ),
        ),
        SizedBox(
          width: 220,
          child: TextField(
            key: ContestFilterBar.venueField,
            controller: _venue,
            decoration: const InputDecoration(labelText: 'Venue'),
            onChanged: (value) =>
                widget.onChanged(filters.copyWith(venue: value)),
          ),
        ),
        _dateField(
          ContestFilterBar.fromField,
          'Starts from',
          filters.from,
          true,
        ),
        _dateField(ContestFilterBar.toField, 'Starts to', filters.to, false),
        if (!filters.isEmpty)
          TextButton(
            key: ContestFilterBar.clearButton,
            onPressed: () => widget.onChanged(const ContestFilters()),
            child: const Text('Clear'),
          ),
      ],
    );
  }
}
