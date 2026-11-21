import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_layout.dart';
import '../viewer/paper_style.dart';
import 'scoring_sheet_table_view.dart';

final AppLocalizations _fallbackL10n = AppLocalizationsEn();

AppLocalizations _l10nOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    _fallbackL10n;

/// The body of one printed page of the Scoring Sheet: one table and, when a mark
/// on the sheet needs explaining, a line under it.
class ScoringSheetPageBody extends StatelessWidget {
  const ScoringSheetPageBody({
    super.key,
    required this.layout,
    required this.page,
    required this.number,
    required this.size,
  });

  final ScoringSheetLayout layout;
  final ScoringSheetPage page;

  /// 1-based page number, for the table's name.
  final int number;

  /// The room the page body has.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10nOf(context);
    final legend = layout.legend;
    return SizedBox(
      width: size.width,
      height: size.height,
      // The layout measured every row; the clip only keeps a font that sets
      // wider than measured from drawing past the page.
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: ScoringSheetTableView(
                page: page,
                workingTime: layout.workingTime,
                label: l10n.matrixTableLabel(number),
                prefilled: layout.prefilled,
              ),
            ),
            if (legend != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: ScoringSheetStyle.legendHeight,
                child: Text(
                  legend,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: PaperStyle.body.copyWith(
                    fontSize: 12,
                    height: ScoringSheetStyle.legendHeight / 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
