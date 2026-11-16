import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;

/// The zone key under which an enclosing transaction (the contest score gate)
/// collects the scopes its units of work wrote, so they are announced once,
/// after the outermost commit, and not at all after a rollback.
const pendingAnnouncementsKey = #soarScorePendingAnnouncements;

/// The scopes collected by the enclosing transaction, or null when the caller
/// is not inside one and must announce for itself.
Set<core.SyncScopeKey>? get pendingAnnouncements =>
    Zone.current[pendingAnnouncementsKey] as Set<core.SyncScopeKey>?;
