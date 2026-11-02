import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/report_launcher.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';

void main() {
  group('ReportViewParams', () {
    test('an empty query is the default view', () {
      final params = ReportViewParams.fromQuery(const {});
      expect(params.filters, isEmpty);
      expect(params.paper, isNull);
      expect(params.orientation, isNull);
      expect(params.preview, isFalse);
      expect(params.zoom, isNull);
      expect(params.toQuery(), isEmpty);
    });

    test('round-trips filters, setup, preview and zoom', () {
      const params = ReportViewParams(
        filters: {'from': '2', 'to': '5', 'pct': '1'},
        paper: PaperSize.a4,
        orientation: PageOrientation.portrait,
        preview: true,
        previewExplicit: true,
        zoom: 1.25,
      );
      expect(ReportViewParams.fromQuery(params.toQuery()), params);
    });

    test('ignores unknown values instead of failing', () {
      final params = ReportViewParams.fromQuery(const {
        'paper': 'tabloid',
        'orient': 'sideways',
        'zoom': 'big',
        'back': '1',
      });
      expect(params.paper, isNull);
      expect(params.orientation, isNull);
      expect(params.zoom, isNull);
      expect(params.filters, isEmpty);
    });

    test('zoom can be cleared back to fit', () {
      const params = ReportViewParams(zoom: 1);
      expect(params.copyWith(zoom: () => null).zoom, isNull);
      expect(params.copyWith(preview: true).zoom, 1);
    });

    test('the explicit flags follow the query', () {
      expect(
        ReportViewParams.fromQuery(const {'preview': '0', 'pp': ''}),
        const ReportViewParams(
          preview: false,
          previewExplicit: true,
          printPages: '',
          printPagesExplicit: true,
        ),
      );
      // An empty query names nothing: the stored choices apply.
      const defaultParams = ReportViewParams();
      expect(defaultParams.previewExplicit, isFalse);
      expect(defaultParams.printPagesExplicit, isFalse);
      expect(defaultParams.preview, isFalse);
      expect(defaultParams.printPages, isEmpty);
    });

    test('toQuery names the explicit values and leaves out the unset ones', () {
      const params = ReportViewParams(
        preview: false,
        previewExplicit: true,
        printPages: '2-4',
        printPagesExplicit: true,
      );
      expect(params.toQuery(), {'preview': '0', 'pp': '2-4'});
      const unset = ReportViewParams(preview: true);
      expect(unset.toQuery(), isEmpty);
      // A round trip keeps the flags, not just the values.
      expect(ReportViewParams.fromQuery(params.toQuery()), params);
    });
  });

  group('PageSetup', () {
    test('swaps the sides for landscape', () {
      const portrait = PageSetup(PaperSize.a4, PageOrientation.portrait);
      const landscape = PageSetup(PaperSize.a4, PageOrientation.landscape);
      expect([portrait.width, portrait.height], [794, 1123]);
      expect([landscape.width, landscape.height], [1123, 794]);
      expect(landscape.label, 'A4 · Landscape');
    });
  });

  test('an in-place launch adds back=1 and keeps the query', () {
    expect(
      PlatformReportLauncher.inPlacePath('/a/b?f.to=2'),
      '/a/b?f.to=2&back=1',
    );
    expect(PlatformReportLauncher.inPlacePath('/a/b'), '/a/b?back=1');
  });
}
