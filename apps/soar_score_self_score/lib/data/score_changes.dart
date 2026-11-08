import 'package:flutter/foundation.dart';

/// Counts the scores this app has had accepted. Pages that show score state
/// include the count in their reload key, so one that stays in the navigation
/// stack under the entry form reads again after a submit.
final scoreChanges = ValueNotifier<int>(0);
