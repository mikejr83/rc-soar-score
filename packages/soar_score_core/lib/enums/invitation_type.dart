import 'package:json_annotation/json_annotation.dart';

/// How an invitation link was issued.
///
/// Serializes as the exact text in `plan/data-model/entities/invitation.md`.
enum InvitationType {
  @JsonValue('MagicURL')
  magicUrl,
  @JsonValue('QRCode')
  qrCode,
}
