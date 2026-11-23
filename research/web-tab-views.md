# Web-Only Branches and New-Tab Views

## Web-Only Branches (kIsWeb)

| File                                                                               | Line | Context                                               |
| ---------------------------------------------------------------------------------- | ---- | ----------------------------------------------------- |
| `apps/soar_score_contest/lib/app.dart`                                             | 146  | `if (!kIsWeb)` — app mode notifier setup              |
| `apps/soar_score_contest/lib/app.dart`                                             | 330  | `if (!kIsWeb && appMode != null)` — app mode handling |
| `apps/soar_score_contest/lib/main.dart`                                            | 96   | `assumeOnline: kIsWeb` — bootstrap config             |
| `apps/soar_score_contest/lib/router.dart`                                          | 175  | `if (!kIsWeb)` — refresh listenable merge             |
| `apps/soar_score_contest/lib/router.dart`                                          | 436  | `if (!kIsWeb)` — offline mode guard                   |
| `apps/soar_score_contest/lib/pages/bootstrap_failure_page.dart`                    | 15   | `this.showQuit = !kIsWeb` — quit button               |
| `apps/soar_score_contest/lib/pages/landing_page.dart`                              | 22   | `this.isWeb = kIsWeb` — landing page                  |
| `apps/soar_score_contest/lib/pages/landing_page.dart`                              | 312  | `if (!kIsWeb && monitor != null)` — sync monitor      |
| `apps/soar_score_contest/lib/pages/landing_page.dart`                              | 380  | `if (!kIsWeb)` — offline mode                         |
| `apps/soar_score_contest/lib/pages/contest/report_viewer_page.dart`                | 349  | `if (!kIsWeb)` — printer setup                        |
| `apps/soar_score_contest/lib/services/reports/report_launcher.dart`                | 46   | `if (!kIsWeb)` — in-place vs new-tab launch           |
| `apps/soar_score_contest/lib/services/reports/viewer/platform_report_printer.dart` | 45   | `if (kIsWeb)` — web print fallback                    |
| `apps/soar_score_contest/lib/services/reports/viewer/platform_report_printer.dart` | 103  | `if (kIsWeb)` — PDF save web path                     |
| `apps/soar_score_contest/lib/services/window/window_title_channel.dart`            | 14   | `if (kIsWeb)` — window title on web                   |
| `apps/soar_score_contest/lib/widgets/workspace/workspace_banners.dart`             | 15   | `this.keepsLocalData = !kIsWeb`                       |
| `apps/soar_score_contest/lib/widgets/page_states/page_banner.dart`                 | 228  | `kind.semantics(web: kIsWeb)`                         |
| `apps/soar_score_contest/lib/widgets/new_contest/copy_source_section.dart`         | 48   | `kIsWeb ? ...` — wizard copy                          |
| `apps/soar_score_contest/lib/widgets/new_contest/copy_source_section.dart`         | 390  | `kIsWeb ? ...` — wizard icon                          |

(Note: 19 unique kIsWeb locations exist in the contest app as of this verification; earlier counts of 24 included duplicates.)

## New-Browser-Tab Views

| Page          | File                                           | Opens in New Tab?        | Shows Back Arrow?                                        |
| ------------- | ---------------------------------------------- | ------------------------ | -------------------------------------------------------- |
| Report Viewer | `lib/services/reports/report_launcher.dart:59` | Yes (web only, `_blank`) | Yes — "Back to Reports" when `back=1` query param is set |

The contest app opens **one** type of view in a new browser tab: the report viewer. On web, `ReportLauncher.open()` calls `launchUrl(url, webOnlyWindowName: '_blank')`. On native, it opens in place with a back arrow.

The report viewer page (`lib/pages/contest/report_viewer_page.dart:759`) shows a back arrow when `openedInPlace` is true, which is set when the URL has `back=1`. The "Back to Reports" button appears in the viewer toolbar.

## E2E Phase Files Covering Reports

Two lifecycle phase files cover the reports:

- `apps/soar_score_contest/integration_test/journey/phase_4_setup.dart` — report readiness (line 262), the Draw Matrix viewer (297) and its remembered option (311), the Scoring Sheet (334), and Pilot Scoring Cards (369) including the invitation QR reprint (395).
- `apps/soar_score_contest/integration_test/journey/phase_6_finish.dart` — the Overall Standings report (186): ranking, no Provisional, the Raw score and Flight details options, and the retired pilot's zero cell (242-243). Its remaining steps complete the contest, publish, and save the native file export.
