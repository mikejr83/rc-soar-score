import 'package:equatable/equatable.dart';

import '../models/id.dart';
import 'score_entry_result.dart';

/// One score of a bulk entry: the same fields as a single entry, plus the
/// slot it is for.
class BulkScoreEntry extends Equatable {
  const BulkScoreEntry({
    required this.assignmentId,
    required this.clientMutationId,
    required this.baseScoreRevision,
    required this.components,
    this.reason,
  });

  final Id assignmentId;
  final String clientMutationId;
  final int baseScoreRevision;
  final Map<String, Object?> components;
  final String? reason;

  @override
  List<Object?> get props => [
    assignmentId,
    clientMutationId,
    baseScoreRevision,
    components,
    reason,
  ];
}

/// What happened to one entry of a bulk request: it was stored ([result]) or
/// refused ([statusCode], [code] and [message], the same as the single entry
/// would have answered).
class BulkScoreOutcome extends Equatable {
  const BulkScoreOutcome.saved(
    ScoreEntryResult this.result, {
    this.replayed = false,
  }) : statusCode = 201,
       code = null,
       message = null;

  const BulkScoreOutcome.refused({
    required int this.statusCode,
    required String this.code,
    required String this.message,
  }) : result = null,
       replayed = false;

  factory BulkScoreOutcome.fromJson(Map<String, Object?> json) {
    final result = json['result'];
    if (result != null) {
      return BulkScoreOutcome.saved(
        ScoreEntryResult.fromJson(result as Map<String, Object?>),
      );
    }
    final error = json['error']! as Map<String, Object?>;
    return BulkScoreOutcome.refused(
      statusCode: error['status']! as int,
      code: error['code']! as String,
      message: error['message']! as String,
    );
  }

  /// The stored entry, or null when it was refused.
  final ScoreEntryResult? result;
  final int? statusCode;
  final String? code;
  final String? message;

  bool get isSaved => result != null;

  /// For a saved entry: it was stored by an earlier request with the same
  /// mutation id, and this request stored nothing for it. Not sent over the
  /// wire; the recalculation and publish that follow only run for entries
  /// stored now.
  final bool replayed;

  bool get isNewlyStored => isSaved && !replayed;

  Map<String, Object?> toJson() => result != null
      ? {'result': result!.toJson()}
      : {
          'error': {'status': statusCode, 'code': code, 'message': message},
        };

  @override
  List<Object?> get props => [result, statusCode, code, message];
}
