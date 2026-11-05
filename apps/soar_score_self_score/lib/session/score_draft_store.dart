import 'dart:convert';

import 'key_value_store.dart';

/// A score send that has not been answered yet. Its id is reused for every
/// retry, so the server never stores the score twice.
class PendingSubmission {
  const PendingSubmission({
    required this.mutationId,
    required this.matrixRevision,
  });

  factory PendingSubmission.fromJson(Map<String, Object?> json) =>
      PendingSubmission(
        mutationId: json['mutationId']! as String,
        matrixRevision: json['matrixRevision']! as int,
      );

  final String mutationId;
  final int matrixRevision;

  Map<String, Object?> toJson() => {
    'mutationId': mutationId,
    'matrixRevision': matrixRevision,
  };
}

/// What the pilot has typed for one flight, kept so a reload or a dead
/// connection loses nothing. Not a score: nothing here is official.
class ScoreDraft {
  const ScoreDraft({
    this.time = '',
    this.height = '',
    this.penalty = '0',
    this.landingId,
    this.lateLanding = false,
    this.motorRestart = false,
    this.outOfBounds = false,
    this.noAltitude = false,
    this.pending,
  });

  factory ScoreDraft.fromJson(Map<String, Object?> json) => ScoreDraft(
    time: json['time'] as String? ?? '',
    height: json['height'] as String? ?? '',
    penalty: json['penalty'] as String? ?? '0',
    landingId: json['landingId'] as String?,
    lateLanding: json['lateLanding'] as bool? ?? false,
    motorRestart: json['motorRestart'] as bool? ?? false,
    outOfBounds: json['outOfBounds'] as bool? ?? false,
    noAltitude: json['noAltitude'] as bool? ?? false,
    pending: json['pending'] == null
        ? null
        : PendingSubmission.fromJson(
            (json['pending']! as Map).cast<String, Object?>(),
          ),
  );

  final String time;
  final String height;
  final String penalty;
  final String? landingId;
  final bool lateLanding;
  final bool motorRestart;
  final bool outOfBounds;
  final bool noAltitude;

  /// Set once the pilot has pressed Submit and until the server answers.
  final PendingSubmission? pending;

  Map<String, Object?> toJson() => {
    'time': time,
    'height': height,
    'penalty': penalty,
    'landingId': landingId,
    'lateLanding': lateLanding,
    'motorRestart': motorRestart,
    'outOfBounds': outOfBounds,
    'noAltitude': noAltitude,
    'pending': pending?.toJson(),
  };
}

/// Keeps one [ScoreDraft] per flight.
class ScoreDraftStore {
  const ScoreDraftStore(this._store);

  final KeyValueStore _store;

  static String _key(String contestId, String pilotId, int round) =>
      'soar_score_self_score.draft.$contestId.$pilotId.$round';

  ScoreDraft? read(String contestId, String pilotId, int round) {
    try {
      final raw = _store.read(_key(contestId, pilotId, round));
      if (raw == null) return null;
      return ScoreDraft.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      // A damaged or blocked entry counts as no draft.
      return null;
    }
  }

  void write(String contestId, String pilotId, int round, ScoreDraft draft) {
    try {
      _store.write(_key(contestId, pilotId, round), jsonEncode(draft.toJson()));
    } on Object {
      // Storage can be blocked. The form still works until the page closes.
    }
  }

  void clear(String contestId, String pilotId, int round) {
    try {
      _store.remove(_key(contestId, pilotId, round));
    } on Object {
      // See write.
    }
  }
}
