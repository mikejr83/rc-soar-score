import 'package:flutter/foundation.dart';

/// Counts the scores this app has had accepted. Pages that show score state
/// include the count in their reload key, so one that stays in the navigation
/// stack under the entry form reads again after a submit.
///
/// It is process-wide on purpose. A guest holds one session, so there is one
/// pilot overview to refresh, and a reload is only a read scoped by the
/// session. Tests that depend on the count reset it in `setUp`.
final scoreChanges = ValueNotifier<int>(0);
