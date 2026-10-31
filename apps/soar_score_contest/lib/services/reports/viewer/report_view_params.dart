import 'package:equatable/equatable.dart';

import 'page_setup.dart';

/// What the URL of a report holds: its filters and options, the page setup,
/// print preview and zoom. Refreshing the tab, copying the link or reopening
/// it restores the same view. The viewer keeps the user's changes in the URL
/// and, separately, in the account's local UI settings; a value the user
/// never chose is not named here at all.
class ReportViewParams extends Equatable {
  const ReportViewParams({
    this.filters = const {},
    this.paper,
    this.orientation,
    this.preview = false,
    this.previewExplicit = false,
    this.zoom,
    this.printPages = '',
    this.printPagesExplicit = false,
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
    final preview = query.containsKey('preview');
    final printPages = query.containsKey('pp');
    return ReportViewParams(
      filters: {
        for (final entry in query.entries)
          if (entry.key.startsWith(_filterPrefix))
            entry.key.substring(_filterPrefix.length): entry.value,
      },
      paper: pick(PaperSize.values, query['paper']),
      orientation: pick(PageOrientation.values, query['orient']),
      preview: query['preview'] == '1',
      previewExplicit: preview,
      zoom: double.tryParse(query['zoom'] ?? ''),
      printPages: query['pp'] ?? '',
      printPagesExplicit: printPages,
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

  /// Whether [preview] was chosen by the user or the link, not just the
  /// default: a URL that names it, or a change in the viewer. A `false`
  /// with [preview] `false` means "never chosen", and the stored choice
  /// applies.
  final bool previewExplicit;

  /// A fixed zoom; `null` fits the page to the width.
  final double? zoom;

  /// The pages to print or save as typed (`2-4`); empty for every page.
  final String printPages;

  /// Whether [printPages] was chosen by the user or the link, not just the
  /// default: a URL that names it, or a change in the viewer. A `false`
  /// with an empty value means "never chosen", and the stored choice
  /// applies.
  final bool printPagesExplicit;

  ReportViewParams copyWith({
    Map<String, String>? filters,
    PaperSize? paper,
    PageOrientation? orientation,
    bool? preview,
    bool? previewExplicit,
    double? Function()? zoom,
    String? printPages,
    bool? printPagesExplicit,
  }) => ReportViewParams(
    filters: filters ?? this.filters,
    paper: paper ?? this.paper,
    orientation: orientation ?? this.orientation,
    preview: preview ?? this.preview,
    previewExplicit: previewExplicit ?? this.previewExplicit,
    zoom: zoom == null ? this.zoom : zoom(),
    printPages: printPages ?? this.printPages,
    printPagesExplicit: printPagesExplicit ?? this.printPagesExplicit,
  );

  /// The query that restores these params; values the user never chose are
  /// left out.
  Map<String, String> toQuery() => {
    for (final entry in filters.entries)
      '$_filterPrefix${entry.key}': entry.value,
    if (paper != null) 'paper': paper!.name,
    if (orientation != null) 'orient': orientation!.name,
    if (previewExplicit) 'preview': preview ? '1' : '0',
    if (zoom != null) 'zoom': '$zoom',
    if (printPagesExplicit) 'pp': printPages,
  };

  @override
  List<Object?> get props => [
    filters,
    paper,
    orientation,
    preview,
    previewExplicit,
    zoom,
    printPages,
    printPagesExplicit,
  ];
}
