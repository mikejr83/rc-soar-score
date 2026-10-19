import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/contest_draft_provider.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';

/// The app's draft store; call it from the main page.
ContestDraftStore draftStoreOf(WidgetTester tester) =>
    contestDraftStoreOf(tester.element(find.byType(HomePage)))!;

/// Puts [draft] into the account's stored draft, as an earlier run of the app
/// would have left it. Call it on the main page, before the wizard has been
/// opened in this run.
Future<void> storeDraftFromEarlierRun(
  DraftPersistence persistence,
  ContestDraft draft,
) => persistence.save(persistence.accountId, draft, DateTime.now());

/// What is stored for the current account now.
Future<StoredDraft> storedDraft(DraftPersistence persistence) =>
    persistence.load(persistence.accountId);
