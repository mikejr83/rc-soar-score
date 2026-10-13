import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'reason_text.dart';

/// A change the service refused, with what it said.
class RefusedChange extends Equatable {
  const RefusedChange({
    required this.entityType,
    required this.entityId,
    required this.madeAt,
    this.reasonCode,
    this.message,
  });

  /// The kind of data, for example `OfficialScore`.
  final String entityType;
  final Id entityId;

  /// When the change was made on this device.
  final DateTime madeAt;

  /// The service's reason code, for example `locked`.
  final String? reasonCode;

  /// The service's explanation, when it gave one.
  final String? message;

  /// The reason in words: the service's message, else the code spelled out.
  String get reason {
    final text = message;
    if (text != null && text.trim().isNotEmpty) return text;
    return reasonText(reasonCode);
  }

  @override
  List<Object?> get props => [
    entityType,
    entityId,
    madeAt,
    reasonCode,
    message,
  ];
}
