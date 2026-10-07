import 'package:flutter/material.dart';

import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/draft_dates.dart';
import '../../services/new_contest/draft_validation.dart';
import '../../services/new_contest/time_zones.dart';
import 'span_grid.dart';
import 'wizard_section_card.dart';

/// Step 1's contest details: name, venue, dates, location and time zone.
///
/// Errors show inline only once the user has tried to continue
/// ([showErrors]); after that they update as the user types.
class ContestDetailsSection extends StatefulWidget {
  const ContestDetailsSection({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.focusNodes,
    required this.showErrors,
    required this.narrow,
  });

  final ContestDraft draft;
  final ValueChanged<ContestDraft> onChanged;

  /// Focus targets for the validation summary's links.
  final Map<DetailsField, FocusNode> focusNodes;

  final bool showErrors;
  final bool narrow;

  @override
  State<ContestDetailsSection> createState() => _ContestDetailsSectionState();
}

class _ContestDetailsSectionState extends State<ContestDetailsSection> {
  late final TextEditingController _name;
  late final TextEditingController _venue;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _country;
  late final String _deviceZone = TimeZones.device();

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _name = TextEditingController(text: draft.name);
    _venue = TextEditingController(text: draft.venue);
    _start = TextEditingController(text: draft.startDate);
    _end = TextEditingController(text: draft.endDate);
    _city = TextEditingController(text: draft.city);
    _region = TextEditingController(text: draft.region);
    _country = TextEditingController(text: draft.country);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _venue,
      _start,
      _end,
      _city,
      _region,
      _country,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Records a new start date and shows the end date that follows it.
  void _changeStart(String text) {
    final next = DraftDates.withStartDate(widget.draft, text);
    if (next.endDate != _end.text) {
      _end.text = next.endDate;
    }
    widget.onChanged(next);
  }

  Future<void> _pickDate(TextEditingController controller, bool start) async {
    final current =
        DraftValidation.parseDate(controller.text) ??
        DraftValidation.parseDate(widget.draft.startDate) ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: start ? 'Start date' : 'End date',
    );
    if (picked == null || !mounted) {
      return;
    }
    final text = DraftValidation.dateFormat.format(picked);
    controller.text = text;
    if (start) {
      _changeStart(text);
    } else {
      widget.onChanged(widget.draft.copyWith(endDate: text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final errors = widget.showErrors
        ? DraftValidation.details(draft)
        : const <DetailsField, String>{};
    final narrow = widget.narrow;

    Widget field({
      required String keyName,
      required TextEditingController controller,
      required String label,
      required ValueChanged<String> onChanged,
      DetailsField? check,
      String? helper,
      String? hint,
      Widget? suffix,
    }) {
      final error = check == null ? null : errors[check];
      return TextField(
        key: ValueKey('contest-$keyName'),
        controller: controller,
        focusNode: check == null ? null : widget.focusNodes[check],
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          errorText: error,
          errorMaxLines: 2,
          suffixIcon:
              suffix ?? (error == null ? null : const Icon(Icons.error)),
        ),
      );
    }

    Widget dateField(TextEditingController controller, bool start) => field(
      keyName: start ? 'start' : 'end',
      controller: controller,
      label: start ? 'Start date *' : 'End date *',
      hint: 'MMM D, YYYY',
      check: start ? DetailsField.startDate : DetailsField.endDate,
      onChanged: (value) => start
          ? _changeStart(value)
          : widget.onChanged(draft.copyWith(endDate: value)),
      suffix: IconButton(
        tooltip: start ? 'Choose the start date' : 'Choose the end date',
        icon: Icon(
          Icons.calendar_today,
          color:
              errors.containsKey(
                start ? DetailsField.startDate : DetailsField.endDate,
              )
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        onPressed: () => _pickDate(controller, start),
      ),
    );

    final zone = draft.timeZone ?? _deviceZone;
    return WizardSectionCard(
      title: 'Contest details',
      trailing: '* Required',
      child: SpanGrid(
        items: [
          SpanGridItem(
            span: 6,
            child: field(
              keyName: 'name',
              controller: _name,
              label: 'Contest name *',
              check: DetailsField.name,
              onChanged: (value) =>
                  widget.onChanged(draft.copyWith(name: value)),
            ),
          ),
          SpanGridItem(
            span: 6,
            child: field(
              keyName: 'venue',
              controller: _venue,
              label: 'Venue / host *',
              check: DetailsField.venue,
              helper: 'Field name or host club as it should appear on results.',
              onChanged: (value) =>
                  widget.onChanged(draft.copyWith(venue: value)),
            ),
          ),
          SpanGridItem(span: 3, child: dateField(_start, true)),
          SpanGridItem(span: 3, child: dateField(_end, false)),
          SpanGridItem(
            span: narrow ? 6 : 2,
            child: field(
              keyName: 'city',
              controller: _city,
              label: 'City',
              onChanged: (value) =>
                  widget.onChanged(draft.copyWith(city: value)),
            ),
          ),
          SpanGridItem(
            span: narrow ? 3 : 2,
            child: field(
              keyName: 'region',
              controller: _region,
              label: 'State / province',
              onChanged: (value) =>
                  widget.onChanged(draft.copyWith(region: value)),
            ),
          ),
          SpanGridItem(
            span: narrow ? 3 : 2,
            child: field(
              keyName: 'country',
              controller: _country,
              label: 'Country',
              onChanged: (value) =>
                  widget.onChanged(draft.copyWith(country: value)),
            ),
          ),
          SpanGridItem(
            span: 6,
            child: DropdownButtonFormField<String>(
              key: const ValueKey('contest-time-zone'),
              initialValue: zone,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Time zone',
                helperText: 'Defaults to this device’s time zone.',
              ),
              items: [
                for (final option in TimeZones.offered)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      option == _deviceZone ? '$option (this device)' : option,
                    ),
                  ),
              ],
              onChanged: (value) => widget.onChanged(
                draft.copyWith(timeZone: value == _deviceZone ? null : value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
