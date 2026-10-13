import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// A conflict that waits for the director's decision, with both versions.
class OpenConflict extends Equatable {
  const OpenConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.reasonCode,
    this.reason,
    this.acceptedPayload,
    this.competingPayload,
  });

  final Id id;

  /// The kind of data in conflict, for example `OfficialScore`.
  final String entityType;
  final Id entityId;

  /// When the service recorded the conflict.
  final DateTime createdAt;

  final String? reasonCode;

  /// The service's explanation, when it gave one.
  final String? reason;

  /// The state the service applied; null while nothing was applied.
  final Map<String, Object?>? acceptedPayload;

  /// The state of the change that collided with it.
  final Map<String, Object?>? competingPayload;

  /// Why the changes collided, in words.
  String get explanation {
    final text = reason;
    if (text != null && text.trim().isNotEmpty) return text;
    final code = reasonCode;
    if (code == null || code.isEmpty) return 'No reason was given.';
    final words = code.replaceAll('_', ' ');
    return '${words[0].toUpperCase()}${words.substring(1)}.';
  }

  @override
  List<Object?> get props => [
    id,
    entityType,
    entityId,
    createdAt,
    reasonCode,
    reason,
    acceptedPayload,
    competingPayload,
  ];
}
