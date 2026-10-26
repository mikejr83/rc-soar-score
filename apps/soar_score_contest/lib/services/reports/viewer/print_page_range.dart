/// Which pages of a report to print or save, as the director typed them:
/// nothing for every page, or numbers and ranges such as `1`, `2-4` or
/// `1, 3-5`.
///
/// The system print dialog cannot choose pages of a sheet the app draws
/// itself, so the choice is made here and only those pages are sent.
class PrintPageRange {
  const PrintPageRange._(this.pages, this.error);

  /// Every page of a sheet of [pageCount] pages.
  factory PrintPageRange.all(int pageCount) =>
      PrintPageRange._([for (var i = 1; i <= pageCount; i++) i], null);

  /// Reads [text] for a sheet of [pageCount] pages. Blank means every page.
  factory PrintPageRange.parse(String text, int pageCount) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return PrintPageRange.all(pageCount);
    }
    final pages = <int>{};
    for (final part in trimmed.split(RegExp(r'[,;]'))) {
      final piece = part.trim();
      final match = RegExp(r'^(\d+)(?:\s*[-–]\s*(\d+))?$').firstMatch(piece);
      if (match == null) {
        return PrintPageRange._(const [], _message(pageCount));
      }
      final from = int.parse(match.group(1)!);
      final to = match.group(2) == null ? from : int.parse(match.group(2)!);
      if (from < 1 || to > pageCount || from > to) {
        return PrintPageRange._(const [], _message(pageCount));
      }
      pages.addAll([for (var i = from; i <= to; i++) i]);
    }
    return PrintPageRange._(pages.toList()..sort(), null);
  }

  static String _message(int pageCount) => pageCount == 1
      ? 'This sheet has one page.'
      : 'Use page numbers from 1 to $pageCount, such as 1 or 2-4.';

  /// The page numbers (1-based) to print, ascending; empty when [error] is set.
  final List<int> pages;

  /// Why the text is not a range, or `null`.
  final String? error;

  bool get isValid => error == null;
}
