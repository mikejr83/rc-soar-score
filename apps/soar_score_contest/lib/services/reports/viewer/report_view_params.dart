import 'package:equatable/equatable.dart';

import 'page_setup.dart';

/// What the URL of a report holds: its filters and options, the page setup,
/// print preview and zoom. Refreshing the tab, copying the link or reopening
/// it restores the same view. Nothing here is stored between sessions.
class ReportViewParams extends Equatable {
  const ReportViewParams({
    this.filters = const {},
    this.paper,
    this.orientation,
    this.preview = false,
    this.zoom,
  });

  /// Reads the params from a URL query.
  factory ReportViewParams.fromQuery(Map<String, String> query) {
    T? pick<T extends Enum>(List<T> values, String? name) {
      for (final value in values) {
        if (value.name == name) {
          return value;
        }
      }
      return null;
    }

    return ReportViewParams(
      filters: {
        for (final entry in query.entries)
          if (entry.key.startsWith(_filterPrefix))
            entry.key.substring(_filterPrefix.length): entry.value,
      },
      paper: pick(PaperSize.values, query['paper']),
      orientation: pick(PageOrientation.values, query['orient']),
      preview: query['preview'] == '1',
      zoom: double.tryParse(query['zoom'] ?? ''),
    );
  }

  static const _filterPrefix = 'f.';

  /// The report's own filters and options, by key.
  final Map<String, String> filters;

  /// Chosen paper; `null` means the locale's default.
  final PaperSize? paper;

  /// Chosen orientation; `null` means the report's own default.
  final PageOrientation? orientation;

  /// Print preview hides screen-only marks.
  final bool preview;

  /// A fixed zoom; `null` fits the page to the width.
  final double? zoom;

  ReportViewParams copyWith({
    Map<String, String>? filters,
    PaperSize? paper,
    PageOrientation? orientation,
    bool? preview,
    double? Function()? zoom,
  }) => ReportViewParams(
    filters: filters ?? this.filters,
    paper: paper ?? this.paper,
    orientation: orientation ?? this.orientation,
    preview: preview ?? this.preview,
    zoom: zoom == null ? this.zoom : zoom(),
  );

  /// The query that restores these params; empty values are left out.
  Map<String, String> toQuery() => {
    for (final entry in filters.entries)
      '$_filterPrefix${entry.key}': entry.value,
    if (paper != null) 'paper': paper!.name,
    if (orientation != null) 'orient': orientation!.name,
    if (preview) 'preview': '1',
    if (zoom != null) 'zoom': '$zoom',
  };

  @override
  List<Object?> get props => [filters, paper, orientation, preview, zoom];
}
