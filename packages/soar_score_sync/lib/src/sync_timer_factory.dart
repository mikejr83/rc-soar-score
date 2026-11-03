import 'dart:async';

/// Starts a [Timer]; replaceable in tests.
typedef SyncTimerFactory = Timer Function(Duration delay, void Function() run);
