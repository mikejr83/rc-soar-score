import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/print_page_range.dart';
import 'report_definition.dart';

/// The Filter, Options and Page groups, in that order, each with a heading.
/// The same controls serve a side panel, a collapsible bar and a bottom sheet;
/// [columns] lays them out side by side when there is room.
class ViewerPanelGroups extends StatelessWidget {
  const ViewerPanelGroups({
    super.key,
    required this.groups,
    required this.setup,
    required this.locale,
    required this.preview,
    required this.onPaper,
    required this.onOrientation,
    required this.onPreview,
    required this.defaultOrientation,
    this.columns = 1,
    this.showOrientation = true,
    this.pageCount = 0,
    this.printPages = '',
    this.onPrintPages,
  });

  /// The report's own groups (Filter, Options).
  final List<ReportControlGroup> groups;
  final PageSetup setup;
  final Locale locale;
  final bool preview;
  final ValueChanged<PaperSize> onPaper;
  final ValueChanged<PageOrientation> onOrientation;
  final ValueChanged<bool> onPreview;
  final PageOrientation defaultOrientation;
  final int columns;

  /// False for a report that prints one way only.
  final bool showOrientation;

  /// The pages the sheet has, for the "Pages to print" field; 0 hides it.
  final int pageCount;
  final String printPages;
  final ValueChanged<String>? onPrintPages;

  @override
  Widget build(BuildContext context) {
    final all = [
      for (var i = 0; i < groups.length; i++)
        _Group(
          number: i + 1,
          title: groups[i].title,
          children: groups[i].children,
        ),
      _Group(
        number: groups.length + 1,
        title: 'Page',
        children: [
          _Segments<PaperSize>(
            label: 'Paper',
            values: PaperSize.values,
            selected: setup.paper,
            text: (paper) => paper.label,
            onChanged: onPaper,
            help: setup.paper.defaultNote(
              locale,
              system: PlatformDispatcher.instance.locale,
            ),
          ),
          if (showOrientation)
            _Segments<PageOrientation>(
              label: 'Orientation',
              values: PageOrientation.values,
              selected: setup.orientation,
              text: (orientation) => orientation.label,
              onChanged: onOrientation,
              help: 'This report’s default is ${defaultOrientation.label}.',
            ),
          if (pageCount > 0 && onPrintPages != null)
            _PrintPagesField(
              pageCount: pageCount,
              text: printPages,
              onChanged: onPrintPages!,
            ),
          SwitchListTile(
            key: const ValueKey('viewer-preview-switch'),
            value: preview,
            onChanged: onPreview,
            contentPadding: EdgeInsets.zero,
            title: const Text('Print preview'),
            subtitle: const Text(
              'Hide screen-only marks and page-break labels',
            ),
          ),
        ],
      ),
    ];
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: all,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [for (final group in all) Expanded(child: group)],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.number,
    required this.title,
    required this.children,
  });

  final int number;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Semantics(
            header: true,
            child: Text(
              '$number · $title',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Segments<T> extends StatelessWidget {
  const _Segments({
    required this.label,
    required this.values,
    required this.selected,
    required this.text,
    required this.onChanged,
    required this.help,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) text;
  final ValueChanged<T> onChanged;
  final String help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          SegmentedButton<T>(
            key: ValueKey('viewer-segments-$label'),
            showSelectedIcon: true,
            segments: [
              for (final value in values)
                ButtonSegment(value: value, label: Text(text(value))),
            ],
            selected: {selected},
            onSelectionChanged: (chosen) => onChanged(chosen.first),
          ),
          Text(
            help,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pages to print": blank for every page, or numbers and ranges such as `1`
/// or `2-4`. Print and Save as PDF send only those pages.
class _PrintPagesField extends StatefulWidget {
  const _PrintPagesField({
    required this.pageCount,
    required this.text,
    required this.onChanged,
  });

  final int pageCount;
  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_PrintPagesField> createState() => _PrintPagesFieldState();
}

class _PrintPagesFieldState extends State<_PrintPagesField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = PrintPageRange.parse(widget.text, widget.pageCount);
    final count = range.pages.length;
    return TextField(
      key: const ValueKey('viewer-print-pages'),
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: 'Pages to print',
        hintText: 'All ${widget.pageCount}',
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: range.error,
        helperText: range.isValid
            ? widget.text.trim().isEmpty
                  ? 'All ${widget.pageCount} '
                        '${widget.pageCount == 1 ? 'page' : 'pages'}. Type 1 or '
                        '2-4 to print only some.'
                  : '$count of ${widget.pageCount} '
                        '${widget.pageCount == 1 ? 'page' : 'pages'} will print.'
            : null,
        helperMaxLines: 2,
      ),
    );
  }
}
