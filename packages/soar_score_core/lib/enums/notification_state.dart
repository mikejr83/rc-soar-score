import 'package:json_annotation/json_annotation.dart';

/// Delivery state of a re-flight notification.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight_participant.md`.
enum NotificationState {
  @JsonValue('NotRequired')
  notRequired,
  @JsonValue('Pending')
  pending,
  @JsonValue('Delivered')
  delivered,
  @JsonValue('Failed')
  failed,
}
