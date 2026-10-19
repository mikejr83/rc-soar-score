import 'package:flutter/widgets.dart';
import 'package:soar_score_contest/services/reports/report_launcher.dart';

/// Records what the reports page opens instead of opening a tab.
class FakeReportLauncher extends ReportLauncher {
  FakeReportLauncher([this.outcome = LaunchOutcome.newTab]);

  LaunchOutcome outcome;
  final List<String> opened = [];
  final List<String> openedHere = [];

  @override
  Future<LaunchOutcome> open(BuildContext context, String path) async {
    opened.add(path);
    return outcome;
  }

  @override
  void openHere(BuildContext context, String path) => openedHere.add(path);
}
